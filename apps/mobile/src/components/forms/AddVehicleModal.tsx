import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  ScrollView,
  TextInput,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { API_BASE_URL } from '../../lib/api';
import { getIdToken } from '../../lib/firebase';
import { Button } from '../ui/Button';

// =============================================================================
// TYPES
// =============================================================================

interface AddVehicleModalProps {
  visible: boolean;
  onClose: () => void;
  householdId: string;
  onSuccess: () => void;
}

// =============================================================================
// COMPONENT
// =============================================================================

export function AddVehicleModal({
  visible,
  onClose,
  householdId,
  onSuccess,
}: AddVehicleModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [nickname, setNickname] = useState('');
  const [make, setMake] = useState('');
  const [model, setModel] = useState('');
  const [year, setYear] = useState('');
  const [color, setColor] = useState('');
  const [licensePlate, setLicensePlate] = useState('');
  const [vin, setVin] = useState('');

  // Insurance
  const [insuranceProvider, setInsuranceProvider] = useState('');
  const [insurancePolicyNum, setInsurancePolicyNum] = useState('');

  const resetForm = () => {
    setNickname('');
    setMake('');
    setModel('');
    setYear('');
    setColor('');
    setLicensePlate('');
    setVin('');
    setInsuranceProvider('');
    setInsurancePolicyNum('');
    setError(null);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleSubmit = async () => {
    if (!make.trim()) {
      setError('Make is required');
      return;
    }
    if (!model.trim()) {
      setError('Model is required');
      return;
    }
    if (!year.trim() || isNaN(parseInt(year))) {
      setError('Valid year is required');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        return;
      }

      const response = await fetch(`${API_BASE_URL}/family/vehicles`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          nickname: nickname.trim() || undefined,
          make: make.trim(),
          model: model.trim(),
          year: parseInt(year),
          color: color.trim() || undefined,
          licensePlate: licensePlate.trim() || undefined,
          vin: vin.trim() || undefined,
          insuranceProvider: insuranceProvider.trim() || undefined,
          insurancePolicyNum: insurancePolicyNum.trim() || undefined,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to add vehicle');
      }

      handleClose();
      onSuccess();
    } catch (err) {
      console.error('Add vehicle error:', err);
      setError('Failed to add vehicle. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const currentYear = new Date().getFullYear();

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={handleClose}
    >
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={handleClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Add Vehicle</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Nickname */}
            <View style={styles.section}>
              <Text style={styles.label}>Nickname</Text>
              <TextInput
                style={styles.input}
                value={nickname}
                onChangeText={setNickname}
                placeholder="e.g., Tom's Car, Family Van"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Year, Make, Model */}
            <View style={styles.row}>
              <View style={[styles.section, styles.flex1]}>
                <Text style={styles.label}>Year *</Text>
                <TextInput
                  style={styles.input}
                  value={year}
                  onChangeText={setYear}
                  placeholder={currentYear.toString()}
                  placeholderTextColor={colors.text.tertiary}
                  keyboardType="number-pad"
                  maxLength={4}
                />
              </View>
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Make *</Text>
              <TextInput
                style={styles.input}
                value={make}
                onChangeText={setMake}
                placeholder="e.g., Toyota, Ford, BMW"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Model *</Text>
              <TextInput
                style={styles.input}
                value={model}
                onChangeText={setModel}
                placeholder="e.g., Camry, F-150, X5"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Color</Text>
              <TextInput
                style={styles.input}
                value={color}
                onChangeText={setColor}
                placeholder="e.g., Black, White, Silver"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>License Plate</Text>
              <TextInput
                style={styles.input}
                value={licensePlate}
                onChangeText={setLicensePlate}
                placeholder="Enter license plate"
                placeholderTextColor={colors.text.tertiary}
                autoCapitalize="characters"
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>VIN</Text>
              <TextInput
                style={styles.input}
                value={vin}
                onChangeText={setVin}
                placeholder="Enter VIN number"
                placeholderTextColor={colors.text.tertiary}
                autoCapitalize="characters"
              />
            </View>

            {/* Insurance */}
            <View style={styles.sectionDivider}>
              <Text style={styles.sectionTitle}>Insurance</Text>
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Provider</Text>
              <TextInput
                style={styles.input}
                value={insuranceProvider}
                onChangeText={setInsuranceProvider}
                placeholder="e.g., State Farm, GEICO"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Policy Number</Text>
              <TextInput
                style={styles.input}
                value={insurancePolicyNum}
                onChangeText={setInsurancePolicyNum}
                placeholder="Enter policy number"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Error */}
            {error && (
              <View style={styles.errorContainer}>
                <Text style={styles.errorText}>{error}</Text>
              </View>
            )}

            {/* Submit Button */}
            <View style={styles.buttonContainer}>
              <Button
                title={isSubmitting ? 'Adding...' : 'Add Vehicle'}
                onPress={handleSubmit}
                disabled={isSubmitting || !make.trim() || !model.trim() || !year.trim()}
                variant="primary"
              />
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

// =============================================================================
// STYLES
// =============================================================================

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
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  placeholder: {
    width: 40,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  section: {
    marginBottom: spacing[4],
  },
  row: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  flex1: {
    flex: 1,
  },
  sectionDivider: {
    marginTop: spacing[4],
    marginBottom: spacing[4],
    paddingBottom: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
  },
  input: {
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  errorContainer: {
    backgroundColor: colors.status.error + '20',
    padding: spacing[3],
    borderRadius: borderRadius.md,
    marginBottom: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.status.error,
    textAlign: 'center',
  },
  buttonContainer: {
    marginTop: spacing[4],
  },
});
