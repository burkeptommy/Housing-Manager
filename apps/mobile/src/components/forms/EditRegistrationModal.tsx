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

interface RegistrationData {
  licensePlate?: string | null;
  vin?: string | null;
  registrationState?: string | null;
  registrationExpiry?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: RegistrationData) => Promise<void>;
  initialData?: RegistrationData;
}

export function EditRegistrationModal({ visible, onClose, onSave, initialData }: Props) {
  const [licensePlate, setLicensePlate] = useState(initialData?.licensePlate || '');
  const [vin, setVin] = useState(initialData?.vin || '');
  const [state, setState] = useState(initialData?.registrationState || '');
  const [expiresAt, setExpiresAt] = useState<Date | null>(
    initialData?.registrationExpiry ? new Date(initialData.registrationExpiry) : null
  );
  const [registrationDoc, setRegistrationDoc] = useState<string | null>(null);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setLicensePlate(initialData?.licensePlate || '');
      setVin(initialData?.vin || '');
      setState(initialData?.registrationState || '');
      setExpiresAt(initialData?.registrationExpiry ? new Date(initialData.registrationExpiry) : null);
      setRegistrationDoc(null);
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        licensePlate: licensePlate.trim() || null,
        vin: vin.trim() || null,
        registrationState: state.trim() || null,
        registrationExpiry: expiresAt?.toISOString() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save registration details');
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
            <Text style={styles.title}>Edit Registration</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Input
              label="License Plate"
              value={licensePlate}
              onChangeText={(v) => setLicensePlate(v.toUpperCase())}
              placeholder="ABC 1234"
              autoCapitalize="characters"
            />

            <Input
              label="VIN"
              value={vin}
              onChangeText={(v) => setVin(v.toUpperCase())}
              placeholder="Vehicle Identification Number"
              autoCapitalize="characters"
              maxLength={17}
            />

            <Input
              label="State"
              value={state}
              onChangeText={setState}
              placeholder="e.g., California"
              autoCapitalize="words"
            />

            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowDatePicker(true)}
            >
              <View style={styles.dateContent}>
                <Text style={styles.dateLabel}>Registration Expiry</Text>
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
              <Text style={styles.uploadLabel}>Registration Document</Text>
              <Text style={styles.uploadHint}>Take a photo of your registration for safekeeping</Text>
              <ImageUpload
                currentImage={registrationDoc}
                onImageSelected={setRegistrationDoc}
                shape="rectangle"
                size="medium"
                placeholder="Upload Registration"
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

export default EditRegistrationModal;
