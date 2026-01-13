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
import DateTimePicker from '@react-native-community/datetimepicker';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { Input } from './Input';
import { Button } from '../ui/Button';
import { ImageUpload } from '../ImageUpload';

interface InsuranceData {
  insuranceProvider?: string | null;
  insurancePolicyNumber?: string | null;
  insuranceExpiresAt?: string | null;
  insuranceDocUrl?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: InsuranceData) => Promise<void>;
  initialData?: InsuranceData;
}

export function EditInsuranceModal({ visible, onClose, onSave, initialData }: Props) {
  const [provider, setProvider] = useState(initialData?.insuranceProvider || '');
  const [policyNumber, setPolicyNumber] = useState(initialData?.insurancePolicyNumber || '');
  const [expiresAt, setExpiresAt] = useState<Date | null>(
    initialData?.insuranceExpiresAt ? new Date(initialData.insuranceExpiresAt) : null
  );
  const [insuranceDoc, setInsuranceDoc] = useState<string | null>(
    initialData?.insuranceDocUrl || null
  );
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setProvider(initialData?.insuranceProvider || '');
      setPolicyNumber(initialData?.insurancePolicyNumber || '');
      setExpiresAt(initialData?.insuranceExpiresAt ? new Date(initialData.insuranceExpiresAt) : null);
      setInsuranceDoc(initialData?.insuranceDocUrl || null);
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        insuranceProvider: provider.trim() || null,
        insurancePolicyNumber: policyNumber.trim() || null,
        insuranceExpiresAt: expiresAt?.toISOString() || null,
        insuranceDocUrl: insuranceDoc,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save insurance details');
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
            <Text style={styles.title}>Edit Insurance</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Input
              label="Insurance Provider"
              value={provider}
              onChangeText={setProvider}
              placeholder="e.g., State Farm, Geico"
              autoCapitalize="words"
            />

            <Input
              label="Policy Number"
              value={policyNumber}
              onChangeText={setPolicyNumber}
              placeholder="Policy number"
              autoCapitalize="characters"
            />

            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowDatePicker(true)}
            >
              <View style={styles.dateContent}>
                <Text style={styles.dateLabel}>Policy Expiry Date</Text>
                <Text style={styles.dateValue}>
                  {expiresAt
                    ? expiresAt.toLocaleDateString('en-US', {
                        month: 'long',
                        day: 'numeric',
                        year: 'numeric',
                      })
                    : 'Not set'}
                </Text>
              </View>
              <Ionicons name="calendar-outline" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>

            {showDatePicker && (
              <DateTimePicker
                value={expiresAt || new Date()}
                mode="date"
                display="spinner"
                onChange={(_: any, date?: Date) => {
                  setShowDatePicker(Platform.OS === 'ios');
                  if (date) setExpiresAt(date);
                }}
              />
            )}

            <View style={styles.uploadSection}>
              <Text style={styles.uploadLabel}>Insurance Card</Text>
              <Text style={styles.uploadHint}>Take a photo of your insurance card for easy access</Text>
              <ImageUpload
                currentImage={insuranceDoc}
                onImageSelected={setInsuranceDoc}
                shape="rectangle"
                size="medium"
                placeholder="Upload Insurance Card"
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
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    marginBottom: spacing[4],
  },
  dateContent: {
    flex: 1,
  },
  dateLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  dateValue: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    marginTop: 2,
  },
  uploadSection: {
    marginTop: spacing[2],
  },
  uploadLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  uploadHint: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: spacing[3],
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

export default EditInsuranceModal;
