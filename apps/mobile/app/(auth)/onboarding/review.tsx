import { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useOnboarding } from '../../../src/contexts/onboarding-context';
import { useAuth } from '../../../src/contexts/auth-context';
import { getApiClient } from '../../../src/lib/api';
import { colors, spacing, typography, borderRadius } from '../../../src/lib/theme';
import type { PropertyFeatures } from '@haven/core';
import { SUBSCRIPTION_PLANS, VENDOR_CATEGORY_LABELS } from '@haven/core';

const PROPERTY_FEATURE_LABELS: { key: keyof PropertyFeatures; label: string }[] = [
  { key: 'hasCentralAc', label: 'Central A/C' },
  { key: 'hasGasHeat', label: 'Gas Heat' },
  { key: 'hasOilHeat', label: 'Oil Heat' },
  { key: 'hasFireplace', label: 'Fireplace' },
  { key: 'hasSeptic', label: 'Septic' },
  { key: 'hasWellWater', label: 'Well Water' },
  { key: 'hasPool', label: 'Pool' },
  { key: 'hasGenerator', label: 'Generator' },
  { key: 'hasLawn', label: 'Lawn' },
  { key: 'hasDriveway', label: 'Driveway' },
];

export default function OnboardingReviewScreen() {
  const router = useRouter();
  const { householdId, homeBasics, bills, taskSelections, selectedPlan, reset } = useOnboarding();
  const { completeOnboarding } = useAuth();
  const api = getApiClient();

  const [isSubmitting, setIsSubmitting] = useState(false);

  const enabledFeatures = PROPERTY_FEATURE_LABELS.filter(
    (f) => homeBasics?.features && homeBasics.features[f.key]
  );

  const selectedTaskCount = taskSelections.filter((s) => s.keep).length;

  // Group bills by type
  const groupedBills = bills.reduce(
    (acc, bill) => {
      const category = bill.category;
      if (['MORTGAGE', 'HOA', 'PROPERTY_TAX'].includes(category)) {
        acc.housing.push(bill);
      } else if (
        ['ELECTRIC', 'GAS', 'WATER_SEWER', 'TRASH', 'INTERNET', 'CABLE', 'MOBILE'].includes(category)
      ) {
        acc.utilities.push(bill);
      } else if (category.includes('INSURANCE')) {
        acc.insurance.push(bill);
      } else if (
        ['CREDIT_CARD', 'STUDENT_LOAN', 'PERSONAL_LOAN', 'VEHICLE_LOAN', 'HELOC'].includes(category)
      ) {
        acc.loans.push(bill);
      } else {
        acc.services.push(bill);
      }
      return acc;
    },
    {
      housing: [] as typeof bills,
      utilities: [] as typeof bills,
      insurance: [] as typeof bills,
      loans: [] as typeof bills,
      services: [] as typeof bills,
    }
  );

  const totalMonthlyBills = bills.reduce((sum, bill) => {
    if (!bill.typicalAmount) return sum;
    const frequencyMultiplier: Record<string, number> = {
      WEEKLY: 4.33,
      BIWEEKLY: 2.17,
      MONTHLY: 1,
      QUARTERLY: 0.33,
      SEMIANNUALLY: 0.167,
      ANNUAL: 0.083,
      OTHER: 1,
      PER_VISIT: 1,
      PER_JOB: 1,
    };
    return sum + bill.typicalAmount * (frequencyMultiplier[bill.billingFrequency] || 1);
  }, 0);

  const handleFinish = async () => {
    if (!householdId) {
      Alert.alert('Error', 'Missing household information');
      return;
    }

    setIsSubmitting(true);
    try {
      // Create subscription if plan selected
      if (selectedPlan) {
        try {
          await api.createSubscription({
            tier: selectedPlan === 'ESSENTIALS' ? 'BASIC' : 'PREMIUM',
            paymentMethodId: 'skip_for_now',
          });
        } catch {
          console.warn('Subscription creation skipped - no payment method');
        }
      }

      // Complete onboarding
      await completeOnboarding(householdId);
      reset();

      // Navigate to main app
      router.replace('/(tabs)');
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to complete setup');
      setIsSubmitting(false);
    }
  };

  const goToStep = (step: number) => {
    const routes = ['index', 'bills', 'maintenance', 'payment', 'review'];
    const route = routes[step - 1];
    if (route && step < 5) {
      router.push(`/(auth)/onboarding/${route === 'index' ? '' : route}`);
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Progress indicator */}
        <View style={styles.progressContainer}>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: '100%' }]} />
          </View>
          <Text style={styles.progressText}>Step 5 of 5</Text>
        </View>

        <View style={styles.header}>
          <Text style={styles.title}>Review your setup</Text>
          <Text style={styles.subtitle}>
            Everything looks good? Let's get you started with Haven!
          </Text>
        </View>

        {/* Property Info */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <View style={styles.sectionTitleRow}>
              <Text style={styles.sectionIcon}>🏠</Text>
              <Text style={styles.sectionTitle}>Property</Text>
            </View>
            <TouchableOpacity onPress={() => goToStep(1)}>
              <Text style={styles.editLink}>Edit</Text>
            </TouchableOpacity>
          </View>

          {homeBasics ? (
            <View style={styles.sectionContent}>
              <Text style={styles.propertyName}>{homeBasics.name}</Text>
              <Text style={styles.addressText}>
                {homeBasics.addressLine1}
                {'\n'}
                {homeBasics.city}, {homeBasics.state} {homeBasics.postalCode}
              </Text>
              <View style={styles.propertyDetails}>
                {homeBasics.squareFeet && (
                  <Text style={styles.detailText}>
                    {homeBasics.squareFeet.toLocaleString()} sq ft
                  </Text>
                )}
                {homeBasics.bedrooms && (
                  <Text style={styles.detailText}>{homeBasics.bedrooms} bed</Text>
                )}
                {homeBasics.bathrooms && (
                  <Text style={styles.detailText}>{homeBasics.bathrooms} bath</Text>
                )}
                {homeBasics.yearBuilt && (
                  <Text style={styles.detailText}>Built {homeBasics.yearBuilt}</Text>
                )}
              </View>
              {enabledFeatures.length > 0 && (
                <View style={styles.featureTags}>
                  {enabledFeatures.map((f) => (
                    <View key={f.key} style={styles.featureTag}>
                      <Text style={styles.featureTagText}>{f.label}</Text>
                    </View>
                  ))}
                </View>
              )}
            </View>
          ) : (
            <Text style={styles.emptyText}>No property information</Text>
          )}
        </View>

        {/* Bills Summary */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <View style={styles.sectionTitleRow}>
              <Text style={styles.sectionIcon}>💳</Text>
              <Text style={styles.sectionTitle}>Bills ({bills.length})</Text>
            </View>
            <TouchableOpacity onPress={() => goToStep(2)}>
              <Text style={styles.editLink}>Edit</Text>
            </TouchableOpacity>
          </View>

          {bills.length > 0 ? (
            <View style={styles.sectionContent}>
              {Object.entries(groupedBills).map(([type, typeBills]) => {
                if (typeBills.length === 0) return null;
                const typeLabels: Record<string, string> = {
                  housing: 'Housing',
                  utilities: 'Utilities',
                  insurance: 'Insurance',
                  loans: 'Loans',
                  services: 'Services',
                };
                return (
                  <View key={type} style={styles.billGroup}>
                    <Text style={styles.billGroupLabel}>{typeLabels[type]}</Text>
                    <View style={styles.billTags}>
                      {typeBills.map((bill) => (
                        <View key={bill.category} style={styles.billTag}>
                          <Text style={styles.billTagText}>
                            {bill.vendorName || VENDOR_CATEGORY_LABELS[bill.category]}
                          </Text>
                        </View>
                      ))}
                    </View>
                  </View>
                );
              })}
              <View style={styles.billTotal}>
                <Text style={styles.billTotalLabel}>Est. monthly total:</Text>
                <Text style={styles.billTotalAmount}>${totalMonthlyBills.toFixed(2)}</Text>
              </View>
            </View>
          ) : (
            <Text style={styles.emptyText}>No bills added</Text>
          )}
        </View>

        {/* Maintenance Summary */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <View style={styles.sectionTitleRow}>
              <Text style={styles.sectionIcon}>🔧</Text>
              <Text style={styles.sectionTitle}>Maintenance Tasks</Text>
            </View>
            <TouchableOpacity onPress={() => goToStep(3)}>
              <Text style={styles.editLink}>Edit</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.sectionContent}>
            <Text style={styles.taskCountText}>
              <Text style={styles.taskCountNumber}>{selectedTaskCount}</Text> maintenance task
              {selectedTaskCount !== 1 ? 's' : ''} scheduled for the first 12 months
            </Text>
          </View>
        </View>

        {/* Subscription Summary */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <View style={styles.sectionTitleRow}>
              <Text style={styles.sectionIcon}>⭐</Text>
              <Text style={styles.sectionTitle}>Subscription</Text>
            </View>
            <TouchableOpacity onPress={() => goToStep(4)}>
              <Text style={styles.editLink}>Edit</Text>
            </TouchableOpacity>
          </View>

          {selectedPlan ? (
            <View style={styles.subscriptionContent}>
              <View>
                <Text style={styles.planName}>{SUBSCRIPTION_PLANS[selectedPlan].name} Plan</Text>
                <Text style={styles.planFeatures}>
                  {SUBSCRIPTION_PLANS[selectedPlan].features.length} features included
                </Text>
              </View>
              <View style={styles.planPriceContainer}>
                <Text style={styles.planPrice}>${SUBSCRIPTION_PLANS[selectedPlan].price}</Text>
                <Text style={styles.planPriceInterval}>/mo</Text>
              </View>
            </View>
          ) : (
            <Text style={styles.emptyText}>No plan selected</Text>
          )}
        </View>

        {/* Confirmation Message */}
        <View style={styles.confirmationCard}>
          <View style={styles.confirmationIcon}>
            <Text style={styles.checkIcon}>✓</Text>
          </View>
          <View style={styles.confirmationText}>
            <Text style={styles.confirmationTitle}>You're all set!</Text>
            <Text style={styles.confirmationSubtitle}>
              Click "Confirm and finish" to complete your setup and start managing your home.
            </Text>
          </View>
        </View>

        {/* Buttons */}
        <View style={styles.buttonRow}>
          <TouchableOpacity
            style={styles.backButton}
            onPress={() => router.back()}
            disabled={isSubmitting}
          >
            <Text style={styles.backButtonText}>Back</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.finishButton, isSubmitting && styles.buttonDisabled]}
            onPress={handleFinish}
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <ActivityIndicator color={colors.white} />
            ) : (
              <Text style={styles.finishButtonText}>Confirm and finish</Text>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  progressContainer: {
    marginBottom: spacing[4],
  },
  progressBar: {
    height: 4,
    backgroundColor: colors.slate[200],
    borderRadius: 2,
    marginBottom: spacing[2],
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.primary[600],
    borderRadius: 2,
  },
  progressText: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    textAlign: 'center',
  },
  header: {
    marginBottom: spacing[4],
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
    marginBottom: spacing[1],
  },
  subtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    lineHeight: 20,
  },
  section: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  sectionIcon: {
    fontSize: 18,
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  editLink: {
    fontSize: typography.fontSizes.sm,
    color: colors.primary[600],
  },
  sectionContent: {},
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
  },
  propertyName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
    marginBottom: spacing[1],
  },
  addressText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
    lineHeight: 20,
    marginBottom: spacing[2],
  },
  propertyDetails: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[3],
  },
  detailText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
  },
  featureTags: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginTop: spacing[3],
  },
  featureTag: {
    backgroundColor: colors.slate[100],
    paddingHorizontal: spacing[2],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
  },
  featureTagText: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[600],
  },
  billGroup: {
    marginBottom: spacing[3],
  },
  billGroupLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[500],
    textTransform: 'uppercase',
    marginBottom: spacing[1],
  },
  billTags: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  billTag: {
    backgroundColor: colors.primary[100],
    paddingHorizontal: spacing[2],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
  },
  billTagText: {
    fontSize: typography.fontSizes.xs,
    color: colors.primary[700],
  },
  billTotal: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.slate[200],
  },
  billTotalLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
  },
  billTotalAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  taskCountText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
  },
  taskCountNumber: {
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  subscriptionContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  planName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  planFeatures: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
  },
  planPriceContainer: {
    flexDirection: 'row',
    alignItems: 'baseline',
  },
  planPrice: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  planPriceInterval: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
  },
  confirmationCard: {
    backgroundColor: colors.green[50],
    borderWidth: 1,
    borderColor: colors.green[200],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    flexDirection: 'row',
    gap: spacing[3],
    marginBottom: spacing[4],
  },
  confirmationIcon: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: colors.green[500],
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkIcon: {
    color: colors.white,
    fontSize: 14,
    fontWeight: typography.fontWeights.bold,
  },
  confirmationText: {
    flex: 1,
  },
  confirmationTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.green[800],
    marginBottom: spacing[1],
  },
  confirmationSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.green[700],
    lineHeight: 18,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  backButton: {
    flex: 1,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.slate[300],
    alignItems: 'center',
  },
  backButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
  },
  finishButton: {
    flex: 1,
    backgroundColor: colors.primary[600],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    alignItems: 'center',
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  finishButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
});
