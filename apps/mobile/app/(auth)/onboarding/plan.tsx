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
import { usePurchases } from '../../../src/contexts/purchases-context';
import { Button, Card, Badge } from '../../../src/components';
import {
  TIER_INFO,
  TierKey,
  formatPrice,
} from '../../../src/lib/purchases';
import {
  colors,
  typography,
  spacing,
  borderRadius,
  shadows,
} from '../../../src/lib/theme';

type BillingPeriod = 'monthly' | 'annual';

export default function OnboardingPlanScreen() {
  const router = useRouter();
  const { setStep } = useOnboarding();
  const { offering, purchase, isLoading } = usePurchases();
  const [selectedTier, setSelectedTier] = useState<TierKey>('haven');
  const [billingPeriod, setBillingPeriod] = useState<BillingPeriod>('annual');
  const [isPurchasing, setIsPurchasing] = useState(false);

  const handlePurchase = async () => {
    if (!offering) {
      // No offerings available - proceed without purchase (free trial mode)
      setStep('complete');
      router.push('/(auth)/onboarding/complete');
      return;
    }

    // Find the right package based on selection
    const pkg = offering.availablePackages.find(
      (p) =>
        p.identifier.toLowerCase().includes(selectedTier) &&
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
      setStep('complete');
      router.push('/(auth)/onboarding/complete');
    } else if (result.error && result.error !== 'Purchase cancelled') {
      Alert.alert('Purchase Failed', result.error);
    }
  };

  const handleSkip = () => {
    // Allow users to skip and continue without subscription
    setStep('complete');
    router.push('/(auth)/onboarding/complete');
  };

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
            const isRecommended = 'recommended' in tier && tier.recommended;
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
                  <View style={styles.planInfo}>
                    <Text style={styles.planName}>{tier.name}</Text>
                    <Text style={styles.planDescription}>
                      {tier.description}
                    </Text>
                  </View>
                  <View style={styles.radioContainer}>
                    <View
                      style={[styles.radio, isSelected && styles.radioSelected]}
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
            <Badge label="1 month free trial" variant="success" />
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
                <Text style={styles.savingsValue}>{formatPrice(savings)}</Text>
              </View>
            )}

            <View style={styles.divider} />

            <View style={styles.summaryRow}>
              <Text style={styles.totalLabel}>Due today</Text>
              <Text style={styles.totalValue}>$0</Text>
            </View>

            <Text style={styles.billingNote}>
              After your free trial, you'll be charged{' '}
              {formatPrice(displayPrice)}
              {isAnnual ? '/year' : '/month'}. Cancel anytime before your trial
              ends.
            </Text>
          </View>
        </Card>

        {/* Action Buttons */}
        <Button
          title={isPurchasing || isLoading ? 'Processing...' : 'Start Free Trial'}
          onPress={handlePurchase}
          loading={isPurchasing || isLoading}
          fullWidth
          icon={
            <Ionicons name="shield-checkmark" size={20} color={colors.white} />
          }
        />

        <TouchableOpacity style={styles.skipButton} onPress={handleSkip}>
          <Text style={styles.skipText}>Skip for now</Text>
        </TouchableOpacity>

        {/* Trust Badges */}
        <View style={styles.trustBadges}>
          <View style={styles.trustItem}>
            <Ionicons
              name="lock-closed"
              size={16}
              color={colors.text.tertiary}
            />
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
    paddingVertical: spacing[2],
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
  planInfo: {
    flex: 1,
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
