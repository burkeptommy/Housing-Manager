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
  Switch,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { Input } from './Input';
import { Button } from '../ui/Button';

interface BenefitsData {
  hasHealthInsurance?: boolean;
  hasDentalInsurance?: boolean;
  paidTimeOffDays?: number | null;
  sickDays?: number | null;
  hasHolidayPay?: boolean;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: BenefitsData) => Promise<void>;
  initialData?: BenefitsData;
}

export function EditBenefitsModal({ visible, onClose, onSave, initialData }: Props) {
  const [hasHealthInsurance, setHasHealthInsurance] = useState(initialData?.hasHealthInsurance ?? false);
  const [hasDentalInsurance, setHasDentalInsurance] = useState(initialData?.hasDentalInsurance ?? false);
  const [paidTimeOffDays, setPaidTimeOffDays] = useState(initialData?.paidTimeOffDays?.toString() || '');
  const [sickDays, setSickDays] = useState(initialData?.sickDays?.toString() || '');
  const [hasHolidayPay, setHasHolidayPay] = useState(initialData?.hasHolidayPay ?? false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setHasHealthInsurance(initialData?.hasHealthInsurance ?? false);
      setHasDentalInsurance(initialData?.hasDentalInsurance ?? false);
      setPaidTimeOffDays(initialData?.paidTimeOffDays?.toString() || '');
      setSickDays(initialData?.sickDays?.toString() || '');
      setHasHolidayPay(initialData?.hasHolidayPay ?? false);
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        hasHealthInsurance,
        hasDentalInsurance,
        paidTimeOffDays: paidTimeOffDays ? parseInt(paidTimeOffDays, 10) : null,
        sickDays: sickDays ? parseInt(sickDays, 10) : null,
        hasHolidayPay,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save benefits info');
    } finally {
      setIsSaving(false);
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
            <Text style={styles.title}>Benefits</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            {/* Insurance Section */}
            <Text style={styles.sectionLabel}>INSURANCE</Text>

            <View style={styles.switchRow}>
              <View style={styles.switchInfo}>
                <Text style={styles.switchLabel}>Health Insurance</Text>
                <Text style={styles.switchDescription}>Employer provides health coverage</Text>
              </View>
              <Switch
                value={hasHealthInsurance}
                onValueChange={setHasHealthInsurance}
                trackColor={{ false: colors.gray[300], true: colors.haven.purple[300] }}
                thumbColor={hasHealthInsurance ? colors.haven.purple[500] : colors.gray[100]}
              />
            </View>

            <View style={styles.switchRow}>
              <View style={styles.switchInfo}>
                <Text style={styles.switchLabel}>Dental Insurance</Text>
                <Text style={styles.switchDescription}>Employer provides dental coverage</Text>
              </View>
              <Switch
                value={hasDentalInsurance}
                onValueChange={setHasDentalInsurance}
                trackColor={{ false: colors.gray[300], true: colors.haven.purple[300] }}
                thumbColor={hasDentalInsurance ? colors.haven.purple[500] : colors.gray[100]}
              />
            </View>

            {/* Time Off Section */}
            <Text style={[styles.sectionLabel, { marginTop: spacing[4] }]}>TIME OFF</Text>

            <Input
              label="Paid Time Off Days"
              value={paidTimeOffDays}
              onChangeText={setPaidTimeOffDays}
              placeholder="0"
              keyboardType="number-pad"
            />

            <Input
              label="Sick Days"
              value={sickDays}
              onChangeText={setSickDays}
              placeholder="0"
              keyboardType="number-pad"
            />

            <View style={styles.switchRow}>
              <View style={styles.switchInfo}>
                <Text style={styles.switchLabel}>Holiday Pay</Text>
                <Text style={styles.switchDescription}>Paid on major holidays</Text>
              </View>
              <Switch
                value={hasHolidayPay}
                onValueChange={setHasHolidayPay}
                trackColor={{ false: colors.gray[300], true: colors.haven.purple[300] }}
                thumbColor={hasHolidayPay ? colors.haven.purple[500] : colors.gray[100]}
              />
            </View>
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
  sectionLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[3],
  },
  switchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  switchInfo: {
    flex: 1,
    marginRight: spacing[3],
  },
  switchLabel: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  switchDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: 2,
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

export default EditBenefitsModal;
