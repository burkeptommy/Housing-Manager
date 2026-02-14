import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  ScrollView,
  Alert,
  Platform,
  KeyboardAvoidingView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { Input } from './Input';
import { Button } from '../ui/Button';

type PayFrequency = 'WEEKLY' | 'BIWEEKLY' | 'MONTHLY' | 'YEARLY';

interface CompensationData {
  payAmount?: number | null;
  payFrequency?: PayFrequency | null;
  paymentMethod?: string | null;
  lastPayDate?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: CompensationData) => Promise<void>;
  initialData?: CompensationData;
}

const PAY_FREQUENCIES: { value: PayFrequency; label: string }[] = [
  { value: 'WEEKLY', label: 'Weekly' },
  { value: 'BIWEEKLY', label: 'Bi-weekly' },
  { value: 'MONTHLY', label: 'Monthly' },
  { value: 'YEARLY', label: 'Yearly' },
];

const PAYMENT_METHODS = [
  { value: 'direct_deposit', label: 'Direct Deposit' },
  { value: 'check', label: 'Check' },
  { value: 'cash', label: 'Cash' },
  { value: 'payroll_service', label: 'Payroll Service' },
];

export function EditCompensationModal({ visible, onClose, onSave, initialData }: Props) {
  const [payAmount, setPayAmount] = useState(initialData?.payAmount?.toString() || '');
  const [payFrequency, setPayFrequency] = useState<PayFrequency | null>(initialData?.payFrequency || null);
  const [paymentMethod, setPaymentMethod] = useState(initialData?.paymentMethod || '');
  const [lastPayDate, setLastPayDate] = useState(initialData?.lastPayDate || '');
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setPayAmount(initialData?.payAmount?.toString() || '');
      setPayFrequency(initialData?.payFrequency || null);
      setPaymentMethod(initialData?.paymentMethod || '');
      setLastPayDate(initialData?.lastPayDate || '');
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        payAmount: payAmount ? parseFloat(payAmount) : null,
        payFrequency: payFrequency,
        paymentMethod: paymentMethod || null,
        lastPayDate: lastPayDate || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save compensation info');
    } finally {
      setIsSaving(false);
    }
  };

  const formatPayLabel = (freq: PayFrequency | null): string => {
    switch (freq) {
      case 'WEEKLY': return 'per week';
      case 'BIWEEKLY': return 'bi-weekly';
      case 'MONTHLY': return 'per month';
      case 'YEARLY': return 'per year';
      default: return '';
    }
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Compensation</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            {/* Pay Amount */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Pay Amount</Text>
              <View style={styles.amountRow}>
                <Text style={styles.currencySymbol}>$</Text>
                <Input
                  value={payAmount}
                  onChangeText={setPayAmount}
                  placeholder="0.00"
                  keyboardType="decimal-pad"
                  containerStyle={styles.amountInput}
                />
                {payFrequency && (
                  <Text style={styles.frequencyLabel}>{formatPayLabel(payFrequency)}</Text>
                )}
              </View>
            </View>

            {/* Pay Frequency */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Pay Frequency</Text>
              <View style={styles.chipContainer}>
                {PAY_FREQUENCIES.map((freq) => (
                  <TouchableOpacity
                    key={freq.value}
                    style={[
                      styles.chip,
                      payFrequency === freq.value && styles.chipActive,
                    ]}
                    onPress={() => setPayFrequency(freq.value)}
                  >
                    <Text
                      style={[
                        styles.chipText,
                        payFrequency === freq.value && styles.chipTextActive,
                      ]}
                    >
                      {freq.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Payment Method */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Payment Method</Text>
              <View style={styles.chipContainer}>
                {PAYMENT_METHODS.map((method) => (
                  <TouchableOpacity
                    key={method.value}
                    style={[
                      styles.chip,
                      paymentMethod === method.value && styles.chipActive,
                    ]}
                    onPress={() => setPaymentMethod(method.value)}
                  >
                    <Text
                      style={[
                        styles.chipText,
                        paymentMethod === method.value && styles.chipTextActive,
                      ]}
                    >
                      {method.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Last Pay Date */}
            <Input
              label="Last Pay Date"
              value={lastPayDate}
              onChangeText={setLastPayDate}
              placeholder="MM/DD/YYYY"
            />
          </ScrollView>

          {/* Footer */}
          <View style={styles.footer}>
            <Button
              title="Cancel"
              variant="outline"
              onPress={onClose}
              style={styles.cancelButton}
            />
            <Button
              title="Save"
              onPress={handleSave}
              loading={isSaving}
              disabled={isSaving}
              style={styles.saveButton}
            />
          </View>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.primary,
  },
  keyboardView: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  closeButton: {
    padding: spacing[2],
    marginLeft: -spacing[2],
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  placeholder: {
    width: 40,
  },
  content: {
    flex: 1,
    padding: spacing[4],
  },
  inputGroup: {
    marginBottom: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  amountRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  currencySymbol: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  amountInput: {
    flex: 1,
    marginBottom: 0,
  },
  frequencyLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  chipContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  chip: {
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    backgroundColor: colors.gray[100],
  },
  chipActive: {
    backgroundColor: colors.haven.purple[500],
  },
  chipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  chipTextActive: {
    color: colors.white,
    fontWeight: typography.fontWeights.medium,
  },
  footer: {
    flexDirection: 'row',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[3],
  },
  cancelButton: {
    flex: 1,
  },
  saveButton: {
    flex: 1,
  },
});

export default EditCompensationModal;
