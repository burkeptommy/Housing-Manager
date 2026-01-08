# Haven Mobile: M05 - Subscriptions & Apple Pay

**Created:** December 29, 2024  
**Priority:** P0 - Revenue critical  
**Estimated Time:** 5-6 hours  
**Dependencies:** M01-M03 complete

---

## CRITICAL RULES

1. **Use RevenueCat** - Simplifies Apple Pay, receipt validation, cross-platform
2. **Annual discount = 2 months free** - Clear value proposition
3. **1 month free trial** on all tiers
4. **Test with sandbox accounts** before production

---

## Overview

Haven's mobile subscription flow:
1. User selects a plan during onboarding (or later in Settings)
2. Apple Pay sheet appears with plan details
3. Receipt validated server-side via RevenueCat
4. Access granted to tier features
5. Subscription managed in Settings

---

## Pricing Structure

| Tier | Monthly | Annual | Annual Savings |
|------|---------|--------|----------------|
| **Essentials** | $39/mo | $390/yr | $78 (2 months free) |
| **Lite** | $349/mo | $3,490/yr | $698 (2 months free) |
| **Haven** | $749/mo | $7,490/yr | $1,498 (2 months free) |
| **Haven+** | $1,499/mo | $14,990/yr | $2,998 (2 months free) |
| **Estate** | $3,499/mo | $34,990/yr | $6,998 (2 months free) |

**All plans include 1 month free trial**

---

## PHASE 1: Install Dependencies

### Task 1.1: Install RevenueCat

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# RevenueCat for subscription management
pnpm add react-native-purchases

# For displaying formatted prices
pnpm add react-native-localize
```

### Task 1.2: Update app.json

Add RevenueCat plugin to `apps/mobile/app.json`:

```json
{
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
      "react-native-purchases",
      {
        "ios": {
          "enableDebugging": true
        }
      }
    ]
  ]
}
```

---

## PHASE 2: RevenueCat Setup

### Task 2.1: Create RevenueCat Configuration

Create `apps/mobile/src/lib/purchases.ts`:

```typescript
import Purchases, {
  LOG_LEVEL,
  PurchasesPackage,
  CustomerInfo,
  PurchasesOffering,
} from 'react-native-purchases';
import { Platform } from 'react-native';
import { IS_DEV } from './config';

// RevenueCat API Keys (replace with your actual keys)
const REVENUECAT_API_KEY_IOS = 'appl_YOUR_REVENUECAT_IOS_KEY';
const REVENUECAT_API_KEY_ANDROID = 'goog_YOUR_REVENUECAT_ANDROID_KEY';

// Haven tier identifiers (must match App Store Connect product IDs)
export const PRODUCT_IDS = {
  // Monthly subscriptions
  ESSENTIALS_MONTHLY: 'haven_essentials_monthly',
  LITE_MONTHLY: 'haven_lite_monthly',
  HAVEN_MONTHLY: 'haven_monthly',
  HAVEN_PLUS_MONTHLY: 'haven_plus_monthly',
  ESTATE_MONTHLY: 'haven_estate_monthly',
  
  // Annual subscriptions
  ESSENTIALS_ANNUAL: 'haven_essentials_annual',
  LITE_ANNUAL: 'haven_lite_annual',
  HAVEN_ANNUAL: 'haven_annual',
  HAVEN_PLUS_ANNUAL: 'haven_plus_annual',
  ESTATE_ANNUAL: 'haven_estate_annual',
} as const;

// Entitlement identifiers
export const ENTITLEMENTS = {
  ESSENTIALS: 'essentials',
  LITE: 'lite',
  HAVEN: 'haven',
  HAVEN_PLUS: 'haven_plus',
  ESTATE: 'estate',
} as const;

// Tier metadata
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
    color: '#627d98', // Haven navy 500
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
    color: '#c4a574', // Champagne
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
    color: '#c4a574', // Champagne
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
    color: '#102a43', // Haven navy 900
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
    color: '#102a43', // Haven navy 900
  },
} as const;

export type TierKey = keyof typeof TIER_INFO;

let isConfigured = false;

/**
 * Initialize RevenueCat
 */
export async function initializePurchases(userId?: string): Promise<void> {
  if (isConfigured) return;

  const apiKey = Platform.OS === 'ios' ? REVENUECAT_API_KEY_IOS : REVENUECAT_API_KEY_ANDROID;

  if (IS_DEV) {
    Purchases.setLogLevel(LOG_LEVEL.DEBUG);
  }

  await Purchases.configure({
    apiKey,
    appUserID: userId || null,
  });

  isConfigured = true;
}

/**
 * Identify user with RevenueCat (call after login)
 */
export async function identifyUser(userId: string): Promise<void> {
  await Purchases.logIn(userId);
}

/**
 * Get available offerings (subscription packages)
 */
export async function getOfferings(): Promise<PurchasesOffering | null> {
  try {
    const offerings = await Purchases.getOfferings();
    return offerings.current;
  } catch (error) {
    console.error('Failed to get offerings:', error);
    return null;
  }
}

/**
 * Get current customer info (subscription status)
 */
export async function getCustomerInfo(): Promise<CustomerInfo> {
  return await Purchases.getCustomerInfo();
}

/**
 * Check if user has specific entitlement
 */
export async function hasEntitlement(entitlementId: string): Promise<boolean> {
  const customerInfo = await getCustomerInfo();
  return customerInfo.entitlements.active[entitlementId]?.isActive === true;
}

/**
 * Get user's current tier
 */
export async function getCurrentTier(): Promise<TierKey | null> {
  const customerInfo = await getCustomerInfo();
  
  // Check tiers from highest to lowest
  if (customerInfo.entitlements.active[ENTITLEMENTS.ESTATE]?.isActive) return 'estate';
  if (customerInfo.entitlements.active[ENTITLEMENTS.HAVEN_PLUS]?.isActive) return 'haven_plus';
  if (customerInfo.entitlements.active[ENTITLEMENTS.HAVEN]?.isActive) return 'haven';
  if (customerInfo.entitlements.active[ENTITLEMENTS.LITE]?.isActive) return 'lite';
  if (customerInfo.entitlements.active[ENTITLEMENTS.ESSENTIALS]?.isActive) return 'essentials';
  
  return null;
}

/**
 * Purchase a package
 */
export async function purchasePackage(
  pkg: PurchasesPackage
): Promise<{ success: boolean; customerInfo?: CustomerInfo; error?: string }> {
  try {
    const { customerInfo } = await Purchases.purchasePackage(pkg);
    return { success: true, customerInfo };
  } catch (error: any) {
    // Handle user cancellation
    if (error.userCancelled) {
      return { success: false, error: 'Purchase cancelled' };
    }
    
    console.error('Purchase error:', error);
    return { success: false, error: error.message || 'Purchase failed' };
  }
}

/**
 * Restore purchases
 */
export async function restorePurchases(): Promise<{
  success: boolean;
  customerInfo?: CustomerInfo;
  error?: string;
}> {
  try {
    const customerInfo = await Purchases.restorePurchases();
    return { success: true, customerInfo };
  } catch (error: any) {
    console.error('Restore error:', error);
    return { success: false, error: error.message || 'Restore failed' };
  }
}

/**
 * Log out user from RevenueCat
 */
export async function logOutPurchases(): Promise<void> {
  await Purchases.logOut();
}

/**
 * Format price for display
 */
export function formatPrice(price: number, currency = 'USD'): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(price);
}

/**
 * Calculate annual savings
 */
export function calculateAnnualSavings(monthlyPrice: number, annualPrice: number): number {
  return (monthlyPrice * 12) - annualPrice;
}
```

---

## PHASE 3: Create Subscription Context

### Task 3.1: Create Purchases Context

Create `apps/mobile/src/contexts/purchases-context.tsx`:

```typescript
import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { CustomerInfo, PurchasesOffering, PurchasesPackage } from 'react-native-purchases';
import { useAuth } from './auth-context';
import {
  initializePurchases,
  identifyUser,
  getOfferings,
  getCustomerInfo,
  getCurrentTier,
  purchasePackage,
  restorePurchases,
  TierKey,
} from '../lib/purchases';

interface PurchasesState {
  isInitialized: boolean;
  isLoading: boolean;
  customerInfo: CustomerInfo | null;
  currentTier: TierKey | null;
  offering: PurchasesOffering | null;
}

interface PurchasesContextType extends PurchasesState {
  purchase: (pkg: PurchasesPackage) => Promise<{ success: boolean; error?: string }>;
  restore: () => Promise<{ success: boolean; error?: string }>;
  refresh: () => Promise<void>;
}

const PurchasesContext = createContext<PurchasesContextType | null>(null);

export function PurchasesProvider({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const [state, setState] = useState<PurchasesState>({
    isInitialized: false,
    isLoading: true,
    customerInfo: null,
    currentTier: null,
    offering: null,
  });

  // Initialize RevenueCat when user changes
  useEffect(() => {
    const init = async () => {
      setState(prev => ({ ...prev, isLoading: true }));

      try {
        await initializePurchases(user?.uid);

        if (user?.uid) {
          await identifyUser(user.uid);
        }

        const [offering, customerInfo, tier] = await Promise.all([
          getOfferings(),
          getCustomerInfo(),
          getCurrentTier(),
        ]);

        setState({
          isInitialized: true,
          isLoading: false,
          customerInfo,
          currentTier: tier,
          offering,
        });
      } catch (error) {
        console.error('Failed to initialize purchases:', error);
        setState(prev => ({
          ...prev,
          isInitialized: true,
          isLoading: false,
        }));
      }
    };

    init();
  }, [user?.uid]);

  const purchase = useCallback(async (pkg: PurchasesPackage) => {
    setState(prev => ({ ...prev, isLoading: true }));

    const result = await purchasePackage(pkg);

    if (result.success && result.customerInfo) {
      const tier = await getCurrentTier();
      setState(prev => ({
        ...prev,
        isLoading: false,
        customerInfo: result.customerInfo!,
        currentTier: tier,
      }));
    } else {
      setState(prev => ({ ...prev, isLoading: false }));
    }

    return result;
  }, []);

  const restore = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true }));

    const result = await restorePurchases();

    if (result.success && result.customerInfo) {
      const tier = await getCurrentTier();
      setState(prev => ({
        ...prev,
        isLoading: false,
        customerInfo: result.customerInfo!,
        currentTier: tier,
      }));
    } else {
      setState(prev => ({ ...prev, isLoading: false }));
    }

    return result;
  }, []);

  const refresh = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true }));

    try {
      const [customerInfo, tier] = await Promise.all([
        getCustomerInfo(),
        getCurrentTier(),
      ]);

      setState(prev => ({
        ...prev,
        isLoading: false,
        customerInfo,
        currentTier: tier,
      }));
    } catch (error) {
      setState(prev => ({ ...prev, isLoading: false }));
    }
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
```

---

## PHASE 4: Create Plan Selection Screen

### Task 4.1: Create Plan Selection Component

Create `apps/mobile/app/(auth)/onboarding/plan.tsx`:

```typescript
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Dimensions,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { PurchasesPackage } from 'react-native-purchases';
import { usePurchases } from '../../../src/contexts/purchases-context';
import { Button, Card, Badge, LoadingSpinner } from '../../../src/components';
import { TIER_INFO, TierKey, formatPrice } from '../../../src/lib/purchases';
import { colors, typography, spacing, borderRadius, shadows } from '../../../src/lib/theme';

const { width } = Dimensions.get('window');

type BillingPeriod = 'monthly' | 'annual';

export default function OnboardingPlanScreen() {
  const router = useRouter();
  const { offering, purchase, isLoading } = usePurchases();
  const [selectedTier, setSelectedTier] = useState<TierKey>('haven');
  const [billingPeriod, setBillingPeriod] = useState<BillingPeriod>('annual');
  const [isPurchasing, setIsPurchasing] = useState(false);

  const handlePurchase = async () => {
    if (!offering) {
      Alert.alert('Error', 'Subscription packages not available');
      return;
    }

    // Find the right package based on selection
    const packageId = `${selectedTier}_${billingPeriod}`;
    const pkg = offering.availablePackages.find(
      p => p.identifier.toLowerCase().includes(selectedTier) && 
           p.identifier.toLowerCase().includes(billingPeriod)
    );

    if (!pkg) {
      Alert.alert('Error', 'Selected plan not available');
      return;
    }

    setIsPurchasing(true);

    const result = await purchase(pkg);

    setIsPurchasing(false);

    if (result.success) {
      router.push('/(auth)/onboarding/complete');
    } else if (result.error && result.error !== 'Purchase cancelled') {
      Alert.alert('Purchase Failed', result.error);
    }
  };

  const handleSkip = () => {
    // Allow users to skip and use free trial
    router.push('/(auth)/onboarding/complete');
  };

  if (isLoading && !offering) {
    return <LoadingSpinner fullScreen message="Loading plans..." />;
  }

  const selectedTierInfo = TIER_INFO[selectedTier];
  const isAnnual = billingPeriod === 'annual';
  const displayPrice = isAnnual 
    ? selectedTierInfo.annualPrice 
    : selectedTierInfo.monthlyPrice;
  const savings = isAnnual 
    ? selectedTierInfo.monthlyPrice * 12 - selectedTierInfo.annualPrice 
    : 0;

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Progress */}
        <View style={styles.progress}>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: '80%' }]} />
          </View>
          <Text style={styles.progressText}>Step 4 of 5</Text>
        </View>

        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>Choose your plan</Text>
          <Text style={styles.subtitle}>
            Start with a 1-month free trial. Cancel anytime.
          </Text>
        </View>

        {/* Billing Toggle */}
        <View style={styles.billingToggle}>
          <TouchableOpacity
            style={[
              styles.toggleButton,
              billingPeriod === 'monthly' && styles.toggleButtonActive,
            ]}
            onPress={() => setBillingPeriod('monthly')}
          >
            <Text
              style={[
                styles.toggleText,
                billingPeriod === 'monthly' && styles.toggleTextActive,
              ]}
            >
              Monthly
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              styles.toggleButton,
              billingPeriod === 'annual' && styles.toggleButtonActive,
            ]}
            onPress={() => setBillingPeriod('annual')}
          >
            <Text
              style={[
                styles.toggleText,
                billingPeriod === 'annual' && styles.toggleTextActive,
              ]}
            >
              Annual
            </Text>
            <Badge label="Save 2 months" variant="champagne" size="sm" />
          </TouchableOpacity>
        </View>

        {/* Plan Cards */}
        <View style={styles.plansContainer}>
          {(Object.keys(TIER_INFO) as TierKey[]).map((tierKey) => {
            const tier = TIER_INFO[tierKey];
            const isSelected = selectedTier === tierKey;
            const isRecommended = tier.recommended;
            const price = isAnnual ? tier.annualPrice : tier.monthlyPrice;

            return (
              <TouchableOpacity
                key={tierKey}
                style={[
                  styles.planCard,
                  isSelected && styles.planCardSelected,
                  isRecommended && styles.planCardRecommended,
                ]}
                onPress={() => setSelectedTier(tierKey)}
                activeOpacity={0.9}
              >
                {isRecommended && (
                  <View style={styles.recommendedBadge}>
                    <Text style={styles.recommendedText}>Most Popular</Text>
                  </View>
                )}

                <View style={styles.planHeader}>
                  <View>
                    <Text style={styles.planName}>{tier.name}</Text>
                    <Text style={styles.planDescription}>{tier.description}</Text>
                  </View>
                  <View style={styles.radioContainer}>
                    <View
                      style={[
                        styles.radio,
                        isSelected && styles.radioSelected,
                      ]}
                    >
                      {isSelected && <View style={styles.radioInner} />}
                    </View>
                  </View>
                </View>

                <View style={styles.priceContainer}>
                  <Text style={styles.price}>
                    {formatPrice(price)}
                    <Text style={styles.pricePeriod}>
                      /{isAnnual ? 'yr' : 'mo'}
                    </Text>
                  </Text>
                  {isAnnual && (
                    <Text style={styles.monthlyEquivalent}>
                      ({formatPrice(Math.round(tier.annualPrice / 12))}/mo)
                    </Text>
                  )}
                </View>

                <View style={styles.featuresContainer}>
                  {tier.features.slice(0, 3).map((feature, idx) => (
                    <View key={idx} style={styles.featureRow}>
                      <Ionicons
                        name="checkmark-circle"
                        size={16}
                        color={colors.status.success}
                      />
                      <Text style={styles.featureText}>{feature}</Text>
                    </View>
                  ))}
                </View>
              </TouchableOpacity>
            );
          })}
        </View>

        {/* Selected Plan Summary */}
        <Card style={styles.summaryCard}>
          <View style={styles.summaryHeader}>
            <Text style={styles.summaryTitle}>Your selection</Text>
            <Badge 
              label="1 month free trial" 
              variant="success" 
            />
          </View>

          <View style={styles.summaryDetails}>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>{selectedTierInfo.name}</Text>
              <Text style={styles.summaryValue}>
                {formatPrice(displayPrice)}/{isAnnual ? 'yr' : 'mo'}
              </Text>
            </View>
            
            {savings > 0 && (
              <View style={styles.summaryRow}>
                <Text style={styles.savingsLabel}>Annual savings</Text>
                <Text style={styles.savingsValue}>
                  {formatPrice(savings)}
                </Text>
              </View>
            )}

            <View style={styles.divider} />

            <View style={styles.summaryRow}>
              <Text style={styles.totalLabel}>Due today</Text>
              <Text style={styles.totalValue}>$0</Text>
            </View>

            <Text style={styles.billingNote}>
              After your free trial, you'll be charged {formatPrice(displayPrice)}
              {isAnnual ? '/year' : '/month'}. Cancel anytime before your trial ends.
            </Text>
          </View>
        </Card>

        {/* Action Buttons */}
        <Button
          title={isPurchasing ? 'Processing...' : 'Start Free Trial'}
          onPress={handlePurchase}
          loading={isPurchasing}
          fullWidth
          icon={<Ionicons name="shield-checkmark" size={20} color={colors.white} />}
        />

        <TouchableOpacity style={styles.skipButton} onPress={handleSkip}>
          <Text style={styles.skipText}>Skip for now</Text>
        </TouchableOpacity>

        {/* Trust Badges */}
        <View style={styles.trustBadges}>
          <View style={styles.trustItem}>
            <Ionicons name="lock-closed" size={16} color={colors.text.tertiary} />
            <Text style={styles.trustText}>Secure payment</Text>
          </View>
          <View style={styles.trustItem}>
            <Ionicons name="refresh" size={16} color={colors.text.tertiary} />
            <Text style={styles.trustText}>Cancel anytime</Text>
          </View>
          <View style={styles.trustItem}>
            <Ionicons name="card" size={16} color={colors.text.tertiary} />
            <Text style={styles.trustText}>Apple Pay</Text>
          </View>
        </View>
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
    paddingBottom: spacing[10],
  },
  progress: {
    marginBottom: spacing[4],
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
    marginBottom: spacing[4],
    alignItems: 'center',
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
  },
  billingToggle: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[1],
    marginBottom: spacing[4],
    ...shadows.sm,
  },
  toggleButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[2.5],
    borderRadius: borderRadius.md,
    gap: spacing[2],
  },
  toggleButtonActive: {
    backgroundColor: colors.haven.navy[900],
  },
  toggleText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  toggleTextActive: {
    color: colors.white,
  },
  plansContainer: {
    gap: spacing[3],
    marginBottom: spacing[4],
  },
  planCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    borderWidth: 2,
    borderColor: 'transparent',
    ...shadows.sm,
  },
  planCardSelected: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.haven.champagne[50],
  },
  planCardRecommended: {
    borderColor: colors.haven.champagne[500],
  },
  recommendedBadge: {
    position: 'absolute',
    top: -10,
    right: spacing[4],
    backgroundColor: colors.haven.champagne[500],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
  },
  recommendedText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  planHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[2],
  },
  planName: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  planDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  radioContainer: {
    padding: spacing[1],
  },
  radio: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    borderColor: colors.border.dark,
    alignItems: 'center',
    justifyContent: 'center',
  },
  radioSelected: {
    borderColor: colors.haven.champagne[500],
  },
  radioInner: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: colors.haven.champagne[500],
  },
  priceContainer: {
    marginBottom: spacing[3],
  },
  price: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  pricePeriod: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.normal,
    color: colors.text.secondary,
  },
  monthlyEquivalent: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  featuresContainer: {
    gap: spacing[2],
  },
  featureRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  featureText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  summaryCard: {
    marginBottom: spacing[4],
    padding: spacing[4],
  },
  summaryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  summaryTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  summaryDetails: {},
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  summaryLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  summaryValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  savingsLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.status.success,
  },
  savingsValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.success,
  },
  divider: {
    height: 1,
    backgroundColor: colors.border.default,
    marginVertical: spacing[3],
  },
  totalLabel: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  totalValue: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.status.success,
  },
  billingNote: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[3],
    lineHeight: 18,
  },
  skipButton: {
    alignItems: 'center',
    paddingVertical: spacing[3],
    marginTop: spacing[2],
  },
  skipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  trustBadges: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: spacing[4],
    marginTop: spacing[4],
  },
  trustItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  trustText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
});
```

---

## PHASE 5: Update Root Layout with Purchases Provider

### Task 5.1: Update _layout.tsx

Update `apps/mobile/app/_layout.tsx`:

```typescript
import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthProvider } from '../src/contexts/auth-context';
import { OnboardingProvider } from '../src/contexts/onboarding-context';
import { PurchasesProvider } from '../src/contexts/purchases-context';
import { colors } from '../src/lib/theme';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <AuthProvider>
          <PurchasesProvider>
            <OnboardingProvider>
              <StatusBar style="dark" />
              <Stack screenOptions={{ headerShown: false }}>
                <Stack.Screen name="index" />
                <Stack.Screen name="(auth)" />
                <Stack.Screen name="(tabs)" />
              </Stack>
            </OnboardingProvider>
          </PurchasesProvider>
        </AuthProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

---

## PHASE 6: App Store Connect Setup (Reference)

### Required In-App Purchase Products

Create these subscription products in App Store Connect:

| Product ID | Type | Duration | Price |
|------------|------|----------|-------|
| haven_essentials_monthly | Auto-Renewable | 1 Month | $39 |
| haven_essentials_annual | Auto-Renewable | 1 Year | $390 |
| haven_lite_monthly | Auto-Renewable | 1 Month | $349 |
| haven_lite_annual | Auto-Renewable | 1 Year | $3,490 |
| haven_monthly | Auto-Renewable | 1 Month | $749 |
| haven_annual | Auto-Renewable | 1 Year | $7,490 |
| haven_plus_monthly | Auto-Renewable | 1 Month | $1,499 |
| haven_plus_annual | Auto-Renewable | 1 Year | $14,990 |
| haven_estate_monthly | Auto-Renewable | 1 Month | $3,499 |
| haven_estate_annual | Auto-Renewable | 1 Year | $34,990 |

**Subscription Group:** Haven Home Management

**Free Trial:** 1 Month (configure in each subscription offer)

---

## PHASE 7: Verification

### Task 7.1: Test Checklist

- [ ] RevenueCat initializes without errors
- [ ] Offerings load and display correctly
- [ ] Plan cards show correct pricing
- [ ] Billing toggle switches between monthly/annual
- [ ] Selected plan highlights properly
- [ ] Annual savings display correctly
- [ ] Free trial badge shows
- [ ] Purchase flow initiates (sandbox)
- [ ] Skip option works
- [ ] Navigation to complete screen works

### Task 7.2: Test Commands

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
pnpm typecheck
pnpm start --ios
```

---

## Summary

After completing this prompt:
1. ✅ RevenueCat integration for subscription management
2. ✅ Apple Pay ready (via RevenueCat)
3. ✅ 5 tier subscription plans
4. ✅ Monthly and annual billing options
5. ✅ 2 months free on annual plans
6. ✅ 1 month free trial on all plans
7. ✅ Beautiful plan selection UI
8. ✅ Purchase flow with error handling

**Next Prompt:** M06 - Core Features Part 1 (Dashboard, Chat, Approvals)
