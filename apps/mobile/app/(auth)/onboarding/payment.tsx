import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useOnboarding } from '../../../src/contexts/onboarding-context';
import { colors, spacing, typography, borderRadius } from '../../../src/lib/theme';
import type { SubscriptionPlan } from '@haven/core';
import { SUBSCRIPTION_PLANS } from '@haven/core';

export default function OnboardingPaymentScreen() {
  const router = useRouter();
  const { setSelectedPlan } = useOnboarding();

  const [selectedPlanId, setSelectedPlanId] = useState<SubscriptionPlan>('ESSENTIALS');
  const [showPaymentForm, setShowPaymentForm] = useState(false);
  const [cardDetails, setCardDetails] = useState({
    cardNumber: '',
    expiry: '',
    cvc: '',
    name: '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleCardNumberChange = (text: string) => {
    let value = text.replace(/\D/g, '');
    if (value.length > 16) value = value.slice(0, 16);
    const formatted = value.replace(/(.{4})/g, '$1 ').trim();
    setCardDetails((prev) => ({ ...prev, cardNumber: formatted }));
  };

  const handleExpiryChange = (text: string) => {
    let value = text.replace(/\D/g, '');
    if (value.length > 4) value = value.slice(0, 4);
    if (value.length >= 2) {
      value = value.slice(0, 2) + '/' + value.slice(2);
    }
    setCardDetails((prev) => ({ ...prev, expiry: value }));
  };

  const handleCvcChange = (text: string) => {
    let value = text.replace(/\D/g, '');
    if (value.length > 4) value = value.slice(0, 4);
    setCardDetails((prev) => ({ ...prev, cvc: value }));
  };

  const handleContinue = () => {
    setIsSubmitting(true);
    // In a real implementation, we would process payment with Stripe here
    // For now, just save the selected plan and continue
    setSelectedPlan(selectedPlanId);
    setIsSubmitting(false);
    router.push('/(auth)/onboarding/review');
  };

  const handleSkip = () => {
    setSelectedPlan(selectedPlanId);
    router.push('/(auth)/onboarding/review');
  };

  const selectedPlanDetails = SUBSCRIPTION_PLANS[selectedPlanId];

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        {/* Progress indicator */}
        <View style={styles.progressContainer}>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: '80%' }]} />
          </View>
          <Text style={styles.progressText}>Step 4 of 5</Text>
        </View>

        <View style={styles.header}>
          <Text style={styles.title}>Choose your plan</Text>
          <Text style={styles.subtitle}>
            Select a subscription plan that fits your needs. You can change this anytime.
          </Text>
        </View>

        {/* Plan Selection */}
        <View style={styles.plansContainer}>
          {(Object.keys(SUBSCRIPTION_PLANS) as SubscriptionPlan[]).map((planId) => {
            const plan = SUBSCRIPTION_PLANS[planId];
            const isSelected = selectedPlanId === planId;

            return (
              <TouchableOpacity
                key={planId}
                style={[styles.planCard, isSelected && styles.planCardSelected]}
                onPress={() => setSelectedPlanId(planId)}
                activeOpacity={0.7}
              >
                <View style={styles.planHeader}>
                  <View
                    style={[
                      styles.radioOuter,
                      isSelected && styles.radioOuterSelected,
                    ]}
                  >
                    {isSelected && <View style={styles.radioInner} />}
                  </View>
                  <View style={styles.planHeaderText}>
                    <View style={styles.planNameRow}>
                      <Text style={styles.planName}>{plan.name}</Text>
                      {planId === 'PREMIUM' && (
                        <View style={styles.recommendedBadge}>
                          <Text style={styles.recommendedText}>Recommended</Text>
                        </View>
                      )}
                    </View>
                  </View>
                  <View style={styles.planPrice}>
                    <Text style={styles.priceAmount}>${plan.price}</Text>
                    <Text style={styles.priceInterval}>/mo</Text>
                  </View>
                </View>

                <View style={styles.featuresList}>
                  {plan.features.map((feature, idx) => (
                    <View key={idx} style={styles.featureItem}>
                      <Text style={styles.featureCheck}>✓</Text>
                      <Text style={styles.featureText}>{feature}</Text>
                    </View>
                  ))}
                </View>
              </TouchableOpacity>
            );
          })}
        </View>

        {/* Payment Method Section */}
        <View style={styles.paymentSection}>
          <Text style={styles.sectionTitle}>Payment Method</Text>

          {!showPaymentForm ? (
            <TouchableOpacity
              style={styles.addPaymentButton}
              onPress={() => setShowPaymentForm(true)}
            >
              <Text style={styles.cardIcon}>💳</Text>
              <Text style={styles.addPaymentText}>
                Add a payment method to complete your subscription
              </Text>
              <TouchableOpacity
                style={styles.addPaymentLink}
                onPress={() => setShowPaymentForm(true)}
              >
                <Text style={styles.addPaymentLinkText}>Add Payment Method</Text>
              </TouchableOpacity>
            </TouchableOpacity>
          ) : (
            <View style={styles.paymentForm}>
              <View style={styles.formField}>
                <Text style={styles.fieldLabel}>Cardholder name</Text>
                <TextInput
                  style={styles.input}
                  placeholder="John Doe"
                  placeholderTextColor={colors.slate[400]}
                  value={cardDetails.name}
                  onChangeText={(text) =>
                    setCardDetails((prev) => ({ ...prev, name: text }))
                  }
                />
              </View>

              <View style={styles.formField}>
                <Text style={styles.fieldLabel}>Card number</Text>
                <TextInput
                  style={[styles.input, styles.monoInput]}
                  placeholder="1234 5678 9012 3456"
                  placeholderTextColor={colors.slate[400]}
                  value={cardDetails.cardNumber}
                  onChangeText={handleCardNumberChange}
                  keyboardType="number-pad"
                />
              </View>

              <View style={styles.formRow}>
                <View style={[styles.formField, { flex: 1 }]}>
                  <Text style={styles.fieldLabel}>Expiry date</Text>
                  <TextInput
                    style={[styles.input, styles.monoInput]}
                    placeholder="MM/YY"
                    placeholderTextColor={colors.slate[400]}
                    value={cardDetails.expiry}
                    onChangeText={handleExpiryChange}
                    keyboardType="number-pad"
                  />
                </View>
                <View style={[styles.formField, { flex: 1 }]}>
                  <Text style={styles.fieldLabel}>CVC</Text>
                  <TextInput
                    style={[styles.input, styles.monoInput]}
                    placeholder="123"
                    placeholderTextColor={colors.slate[400]}
                    value={cardDetails.cvc}
                    onChangeText={handleCvcChange}
                    keyboardType="number-pad"
                    secureTextEntry
                  />
                </View>
              </View>

              <View style={styles.securityNote}>
                <Text style={styles.lockIcon}>🔒</Text>
                <Text style={styles.securityText}>
                  Your payment information is secured with 256-bit SSL encryption
                </Text>
              </View>

              <TouchableOpacity onPress={() => setShowPaymentForm(false)}>
                <Text style={styles.cancelText}>Cancel</Text>
              </TouchableOpacity>
            </View>
          )}
        </View>

        {/* Billing Summary */}
        <View style={styles.summaryCard}>
          <Text style={styles.summaryTitle}>Billing Summary</Text>
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>{selectedPlanDetails.name} Plan</Text>
            <Text style={styles.summaryValue}>${selectedPlanDetails.price}/mo</Text>
          </View>
          <View style={styles.summaryDivider} />
          <View style={styles.summaryRow}>
            <Text style={styles.totalLabel}>Due today</Text>
            <Text style={styles.totalValue}>${selectedPlanDetails.price}</Text>
          </View>
          <Text style={styles.summaryNote}>Cancel anytime. No long-term contracts.</Text>
        </View>

        {/* Skip Option */}
        <TouchableOpacity style={styles.skipLink} onPress={handleSkip}>
          <Text style={styles.skipLinkText}>Skip payment for now - set up later</Text>
        </TouchableOpacity>

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
            style={[styles.continueButton, isSubmitting && styles.buttonDisabled]}
            onPress={handleContinue}
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <ActivityIndicator color={colors.white} />
            ) : (
              <Text style={styles.continueButtonText}>Continue</Text>
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
  plansContainer: {
    gap: spacing[3],
    marginBottom: spacing[4],
  },
  planCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    borderWidth: 2,
    borderColor: colors.slate[200],
  },
  planCardSelected: {
    borderColor: colors.primary[500],
    backgroundColor: colors.primary[50],
  },
  planHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[3],
  },
  radioOuter: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    borderColor: colors.slate[300],
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 2,
  },
  radioOuterSelected: {
    borderColor: colors.primary[600],
  },
  radioInner: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: colors.primary[600],
  },
  planHeaderText: {
    flex: 1,
  },
  planNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  planName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  recommendedBadge: {
    backgroundColor: colors.primary[100],
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  recommendedText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.primary[700],
  },
  planPrice: {
    flexDirection: 'row',
    alignItems: 'baseline',
  },
  priceAmount: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  priceInterval: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
  },
  featuresList: {
    marginTop: spacing[3],
    marginLeft: spacing[8],
    gap: spacing[2],
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  featureCheck: {
    fontSize: 14,
    color: colors.green[500],
  },
  featureText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
  },
  paymentSection: {
    marginBottom: spacing[4],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
    marginBottom: spacing[3],
    paddingBottom: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[200],
  },
  addPaymentButton: {
    borderWidth: 2,
    borderStyle: 'dashed',
    borderColor: colors.slate[300],
    borderRadius: borderRadius.lg,
    padding: spacing[6],
    alignItems: 'center',
  },
  cardIcon: {
    fontSize: 40,
    marginBottom: spacing[2],
  },
  addPaymentText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
    textAlign: 'center',
    marginBottom: spacing[3],
  },
  addPaymentLink: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    backgroundColor: colors.slate[100],
    borderRadius: borderRadius.md,
  },
  addPaymentLinkText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
  },
  paymentForm: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    gap: spacing[3],
  },
  formField: {
    marginBottom: spacing[1],
  },
  fieldLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[600],
    marginBottom: spacing[1],
  },
  input: {
    backgroundColor: colors.slate[50],
    borderWidth: 1,
    borderColor: colors.slate[200],
    borderRadius: borderRadius.md,
    padding: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
  },
  monoInput: {
    fontFamily: 'monospace',
  },
  formRow: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  securityNote: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: spacing[2],
  },
  lockIcon: {
    fontSize: 14,
  },
  securityText: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    flex: 1,
  },
  cancelText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    textAlign: 'center',
    marginTop: spacing[2],
  },
  summaryCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  summaryTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginBottom: spacing[3],
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  summaryLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
  },
  summaryValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  summaryDivider: {
    height: 1,
    backgroundColor: colors.slate[200],
    marginVertical: spacing[3],
  },
  totalLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  totalValue: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  summaryNote: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: spacing[2],
  },
  skipLink: {
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  skipLinkText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
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
  continueButton: {
    flex: 1,
    backgroundColor: colors.primary[600],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    alignItems: 'center',
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  continueButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
});
