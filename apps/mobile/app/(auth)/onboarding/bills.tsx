import { useState, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useOnboarding, type BillEntry } from '../../../src/contexts/onboarding-context';
import { getApiClient } from '../../../src/lib/api';
import { colors, spacing, typography, borderRadius } from '../../../src/lib/theme';
import type { VendorCategory, BillingFrequency, PaymentResponsibility } from '@haven/core';
import {
  BILL_CATEGORY_GROUPS,
  BILLING_FREQUENCY_OPTIONS,
  PAYMENT_RESPONSIBILITY_OPTIONS,
} from '@haven/core';

export default function OnboardingBillsScreen() {
  const router = useRouter();
  const { householdId, setBills, setVendors } = useOnboarding();
  const api = getApiClient();

  // State
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set(['utilities']));
  const [enabledBills, setEnabledBills] = useState<Set<VendorCategory>>(new Set());
  const [billData, setBillData] = useState<Map<VendorCategory, BillEntry>>(new Map());
  const [isLoading, setIsLoading] = useState(false);

  const toggleGroup = useCallback((key: string) => {
    setExpandedGroups((prev) => {
      const next = new Set(prev);
      if (next.has(key)) {
        next.delete(key);
      } else {
        next.add(key);
      }
      return next;
    });
  }, []);

  const toggleBill = useCallback((category: VendorCategory) => {
    setEnabledBills((prev) => {
      const next = new Set(prev);
      if (next.has(category)) {
        next.delete(category);
      } else {
        next.add(category);
        // Initialize bill data if not exists
        if (!billData.has(category)) {
          setBillData((prevData) => {
            const newData = new Map(prevData);
            newData.set(category, {
              category,
              vendorName: '',
              accountNumber: '',
              typicalAmount: null,
              billingFrequency: 'MONTHLY',
              nextDueDate: '',
              paymentResponsibility: 'OWNER_PAYS_DIRECT',
            });
            return newData;
          });
        }
      }
      return next;
    });
  }, [billData]);

  const updateBillField = useCallback(
    (category: VendorCategory, field: keyof BillEntry, value: string | number | null) => {
      setBillData((prev) => {
        const newData = new Map(prev);
        const existing = newData.get(category) || {
          category,
          vendorName: '',
          accountNumber: '',
          typicalAmount: null,
          billingFrequency: 'MONTHLY' as BillingFrequency,
          nextDueDate: '',
          paymentResponsibility: 'OWNER_PAYS_DIRECT' as PaymentResponsibility,
        };
        newData.set(category, { ...existing, [field]: value });
        return newData;
      });
    },
    []
  );

  const getBillData = (category: VendorCategory): BillEntry => {
    return (
      billData.get(category) || {
        category,
        vendorName: '',
        accountNumber: '',
        typicalAmount: null,
        billingFrequency: 'MONTHLY',
        nextDueDate: '',
        paymentResponsibility: 'OWNER_PAYS_DIRECT',
      }
    );
  };

  const getGroupSelectedCount = (groupKey: string) => {
    const group = BILL_CATEGORY_GROUPS.find((g) => g.key === groupKey);
    if (!group) return 0;
    return group.items.filter((item) => enabledBills.has(item.category)).length;
  };

  const handleContinue = async () => {
    if (!householdId) {
      Alert.alert('Error', 'Please complete the previous step first');
      router.back();
      return;
    }

    // Collect valid bills
    const validBills: BillEntry[] = [];
    enabledBills.forEach((category) => {
      const data = billData.get(category);
      if (data && data.vendorName.trim()) {
        validBills.push(data);
      }
    });

    setIsLoading(true);
    try {
      const createdVendors = [];

      // Create vendors and bill accounts
      for (const bill of validBills) {
        const vendor = await api.createHouseholdVendor(householdId, {
          displayName: bill.vendorName,
          category: bill.category,
        });
        createdVendors.push(vendor);

        await api.createBillAccount({
          householdId,
          vendorId: vendor.id,
          nickname: bill.vendorName,
          category: bill.category,
          accountNumber: bill.accountNumber || undefined,
          billingFrequency: bill.billingFrequency,
          paymentResponsibility: bill.paymentResponsibility,
          typicalAmount: bill.typicalAmount || undefined,
          nextDueDate: bill.nextDueDate || undefined,
        });
      }

      setVendors(createdVendors);
      setBills(validBills);
      router.push('/(auth)/onboarding/maintenance');
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to save bills');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSkip = () => {
    setBills([]);
    setVendors([]);
    router.push('/(auth)/onboarding/maintenance');
  };

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
            <View style={[styles.progressFill, { width: '40%' }]} />
          </View>
          <Text style={styles.progressText}>Step 2 of 5</Text>
        </View>

        <View style={styles.header}>
          <Text style={styles.title}>Your recurring bills</Text>
          <Text style={styles.subtitle}>
            Tell us about your recurring bills so we can help you track them. Skip any that don't
            apply.
          </Text>
        </View>

        {/* Bill Category Groups */}
        {BILL_CATEGORY_GROUPS.map((group) => (
          <View key={group.key} style={styles.groupContainer}>
            {/* Group Header */}
            <TouchableOpacity
              style={styles.groupHeader}
              onPress={() => toggleGroup(group.key)}
              activeOpacity={0.7}
            >
              <View style={styles.groupHeaderLeft}>
                <Text style={styles.groupIcon}>{group.icon}</Text>
                <Text style={styles.groupLabel}>{group.label}</Text>
                <Text style={styles.groupCount}>
                  ({getGroupSelectedCount(group.key)} selected)
                </Text>
              </View>
              <Text style={styles.chevron}>{expandedGroups.has(group.key) ? '▲' : '▼'}</Text>
            </TouchableOpacity>

            {/* Group Items */}
            {expandedGroups.has(group.key) && (
              <View style={styles.groupContent}>
                {group.items.map((item) => {
                  const isEnabled = enabledBills.has(item.category);
                  const data = getBillData(item.category);

                  return (
                    <View key={item.category} style={styles.billItem}>
                      {/* Bill Toggle */}
                      <TouchableOpacity
                        style={styles.billToggle}
                        onPress={() => toggleBill(item.category)}
                        activeOpacity={0.7}
                      >
                        <View
                          style={[styles.checkbox, isEnabled && styles.checkboxChecked]}
                        >
                          {isEnabled && <Text style={styles.checkmark}>✓</Text>}
                        </View>
                        <Text style={styles.billLabel}>{item.label}</Text>
                      </TouchableOpacity>

                      {/* Bill Details Form */}
                      {isEnabled && (
                        <View style={styles.billForm}>
                          <View style={styles.formRow}>
                            <View style={styles.formField}>
                              <Text style={styles.fieldLabel}>Vendor name</Text>
                              <TextInput
                                style={styles.input}
                                placeholder="e.g., Duke Energy"
                                placeholderTextColor={colors.slate[400]}
                                value={data.vendorName}
                                onChangeText={(text) =>
                                  updateBillField(item.category, 'vendorName', text)
                                }
                              />
                            </View>
                            <View style={styles.formField}>
                              <Text style={styles.fieldLabel}>Account # (optional)</Text>
                              <TextInput
                                style={styles.input}
                                placeholder="Account number"
                                placeholderTextColor={colors.slate[400]}
                                value={data.accountNumber}
                                onChangeText={(text) =>
                                  updateBillField(item.category, 'accountNumber', text)
                                }
                              />
                            </View>
                          </View>

                          <View style={styles.formRow}>
                            <View style={styles.formField}>
                              <Text style={styles.fieldLabel}>Amount</Text>
                              <TextInput
                                style={styles.input}
                                placeholder="$0.00"
                                placeholderTextColor={colors.slate[400]}
                                value={data.typicalAmount?.toString() || ''}
                                onChangeText={(text) =>
                                  updateBillField(
                                    item.category,
                                    'typicalAmount',
                                    text ? parseFloat(text) : null
                                  )
                                }
                                keyboardType="decimal-pad"
                              />
                            </View>
                            <View style={styles.formField}>
                              <Text style={styles.fieldLabel}>Frequency</Text>
                              <View style={styles.frequencyButtons}>
                                {BILLING_FREQUENCY_OPTIONS.slice(0, 4).map((freq) => (
                                  <TouchableOpacity
                                    key={freq.value}
                                    style={[
                                      styles.freqButton,
                                      data.billingFrequency === freq.value &&
                                        styles.freqButtonActive,
                                    ]}
                                    onPress={() =>
                                      updateBillField(item.category, 'billingFrequency', freq.value)
                                    }
                                  >
                                    <Text
                                      style={[
                                        styles.freqButtonText,
                                        data.billingFrequency === freq.value &&
                                          styles.freqButtonTextActive,
                                      ]}
                                    >
                                      {freq.label.slice(0, 3)}
                                    </Text>
                                  </TouchableOpacity>
                                ))}
                              </View>
                            </View>
                          </View>

                          <View style={styles.paymentSection}>
                            <Text style={styles.fieldLabel}>How is this paid?</Text>
                            {PAYMENT_RESPONSIBILITY_OPTIONS.map((option) => (
                              <TouchableOpacity
                                key={option.value}
                                style={[
                                  styles.paymentOption,
                                  data.paymentResponsibility === option.value &&
                                    styles.paymentOptionActive,
                                ]}
                                onPress={() =>
                                  updateBillField(
                                    item.category,
                                    'paymentResponsibility',
                                    option.value
                                  )
                                }
                              >
                                <View
                                  style={[
                                    styles.radioOuter,
                                    data.paymentResponsibility === option.value &&
                                      styles.radioOuterActive,
                                  ]}
                                >
                                  {data.paymentResponsibility === option.value && (
                                    <View style={styles.radioInner} />
                                  )}
                                </View>
                                <View style={styles.paymentOptionText}>
                                  <Text style={styles.paymentOptionLabel}>{option.label}</Text>
                                  <Text style={styles.paymentOptionDesc}>{option.description}</Text>
                                </View>
                              </TouchableOpacity>
                            ))}
                          </View>
                        </View>
                      )}
                    </View>
                  );
                })}
              </View>
            )}
          </View>
        ))}

        {/* Summary */}
        <View style={styles.summaryCard}>
          <Text style={styles.summaryText}>
            <Text style={styles.summaryCount}>{enabledBills.size}</Text> bill
            {enabledBills.size !== 1 ? 's' : ''} selected. You can always add more later.
          </Text>
        </View>

        {/* Buttons */}
        <View style={styles.buttonRow}>
          <TouchableOpacity
            style={styles.skipButton}
            onPress={handleSkip}
            disabled={isLoading}
          >
            <Text style={styles.skipButtonText}>Skip for now</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.continueButton, isLoading && styles.buttonDisabled]}
            onPress={handleContinue}
            disabled={isLoading}
          >
            {isLoading ? (
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
  groupContainer: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    marginBottom: spacing[3],
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  groupHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
    backgroundColor: colors.slate[50],
  },
  groupHeaderLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  groupIcon: {
    fontSize: 20,
  },
  groupLabel: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  groupCount: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
  },
  chevron: {
    fontSize: 12,
    color: colors.slate[400],
  },
  groupContent: {
    padding: spacing[4],
    paddingTop: spacing[2],
  },
  billItem: {
    marginBottom: spacing[4],
  },
  billToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
  },
  checkbox: {
    width: 22,
    height: 22,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: colors.slate[300],
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkboxChecked: {
    backgroundColor: colors.primary[600],
    borderColor: colors.primary[600],
  },
  checkmark: {
    color: colors.white,
    fontSize: 14,
    fontWeight: typography.fontWeights.bold,
  },
  billLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
  },
  billForm: {
    marginTop: spacing[3],
    marginLeft: spacing[8],
    padding: spacing[3],
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
  },
  formRow: {
    flexDirection: 'row',
    gap: spacing[3],
    marginBottom: spacing[3],
  },
  formField: {
    flex: 1,
  },
  fieldLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[600],
    marginBottom: spacing[1],
  },
  input: {
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.slate[200],
    borderRadius: borderRadius.md,
    padding: spacing[2],
    fontSize: typography.fontSizes.sm,
    color: colors.slate[900],
  },
  frequencyButtons: {
    flexDirection: 'row',
    gap: spacing[1],
  },
  freqButton: {
    flex: 1,
    paddingVertical: spacing[2],
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.slate[200],
    backgroundColor: colors.white,
    alignItems: 'center',
  },
  freqButtonActive: {
    borderColor: colors.primary[600],
    backgroundColor: colors.primary[50],
  },
  freqButtonText: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[600],
  },
  freqButtonTextActive: {
    color: colors.primary[700],
    fontWeight: typography.fontWeights.medium,
  },
  paymentSection: {
    marginTop: spacing[2],
  },
  paymentOption: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    padding: spacing[3],
    marginTop: spacing[2],
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.slate[200],
    backgroundColor: colors.white,
    gap: spacing[3],
  },
  paymentOptionActive: {
    borderColor: colors.primary[500],
    backgroundColor: colors.primary[50],
  },
  radioOuter: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: colors.slate[300],
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 2,
  },
  radioOuterActive: {
    borderColor: colors.primary[600],
  },
  radioInner: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: colors.primary[600],
  },
  paymentOptionText: {
    flex: 1,
  },
  paymentOptionLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
  },
  paymentOptionDesc: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  summaryCard: {
    padding: spacing[4],
    backgroundColor: colors.primary[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[2],
    marginBottom: spacing[4],
  },
  summaryText: {
    fontSize: typography.fontSizes.sm,
    color: colors.primary[800],
  },
  summaryCount: {
    fontWeight: typography.fontWeights.bold,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  skipButton: {
    flex: 1,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.slate[300],
    alignItems: 'center',
  },
  skipButtonText: {
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
