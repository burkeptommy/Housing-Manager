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

interface VetData {
  vetName?: string | null;
  vetClinic?: string | null;
  vetPhone?: string | null;
  vetAddress?: string | null;
  lastVetVisit?: string | null;
  nextVetVisit?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: VetData) => Promise<void>;
  initialData?: VetData;
}

export function EditPetVetModal({ visible, onClose, onSave, initialData }: Props) {
  const [vetName, setVetName] = useState(initialData?.vetName || '');
  const [vetClinic, setVetClinic] = useState(initialData?.vetClinic || '');
  const [vetPhone, setVetPhone] = useState(initialData?.vetPhone || '');
  const [vetAddress, setVetAddress] = useState(initialData?.vetAddress || '');
  const [lastVetVisit, setLastVetVisit] = useState<Date | null>(
    initialData?.lastVetVisit ? new Date(initialData.lastVetVisit) : null
  );
  const [nextVetVisit, setNextVetVisit] = useState<Date | null>(
    initialData?.nextVetVisit ? new Date(initialData.nextVetVisit) : null
  );
  const [showLastVisitPicker, setShowLastVisitPicker] = useState(false);
  const [showNextVisitPicker, setShowNextVisitPicker] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setVetName(initialData?.vetName || '');
      setVetClinic(initialData?.vetClinic || '');
      setVetPhone(initialData?.vetPhone || '');
      setVetAddress(initialData?.vetAddress || '');
      setLastVetVisit(initialData?.lastVetVisit ? new Date(initialData.lastVetVisit) : null);
      setNextVetVisit(initialData?.nextVetVisit ? new Date(initialData.nextVetVisit) : null);
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        vetName: vetName.trim() || null,
        vetClinic: vetClinic.trim() || null,
        vetPhone: vetPhone.trim() || null,
        vetAddress: vetAddress.trim() || null,
        lastVetVisit: lastVetVisit?.toISOString() || null,
        nextVetVisit: nextVetVisit?.toISOString() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save veterinarian details');
    } finally {
      setIsSaving(false);
    }
  };

  const formatDate = (date: Date | null) => {
    if (!date) return 'Not set';
    return date.toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
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
            <Text style={styles.title}>Veterinarian</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Input
              label="Clinic Name"
              value={vetClinic}
              onChangeText={setVetClinic}
              placeholder="e.g., Happy Paws Veterinary Clinic"
              autoCapitalize="words"
            />

            <Input
              label="Veterinarian Name"
              value={vetName}
              onChangeText={setVetName}
              placeholder="e.g., Dr. Smith"
              autoCapitalize="words"
            />

            <Input
              label="Phone"
              value={vetPhone}
              onChangeText={setVetPhone}
              placeholder="(555) 123-4567"
              keyboardType="phone-pad"
            />

            <Input
              label="Address"
              value={vetAddress}
              onChangeText={setVetAddress}
              placeholder="Clinic address"
              multiline
            />

            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowLastVisitPicker(true)}
            >
              <View style={styles.dateContent}>
                <Text style={styles.dateLabel}>Last Visit</Text>
                <Text style={styles.dateValue}>{formatDate(lastVetVisit)}</Text>
              </View>
              <Ionicons name="calendar-outline" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>

            {showLastVisitPicker && (
              <DateTimePicker
                value={lastVetVisit || new Date()}
                mode="date"
                display="spinner"
                onChange={(_: any, date?: Date) => {
                  setShowLastVisitPicker(Platform.OS === 'ios');
                  if (date) setLastVetVisit(date);
                }}
              />
            )}

            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowNextVisitPicker(true)}
            >
              <View style={styles.dateContent}>
                <Text style={styles.dateLabel}>Next Appointment</Text>
                <Text style={styles.dateValue}>{formatDate(nextVetVisit)}</Text>
              </View>
              <Ionicons name="calendar-outline" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>

            {showNextVisitPicker && (
              <DateTimePicker
                value={nextVetVisit || new Date()}
                mode="date"
                display="spinner"
                onChange={(_: any, date?: Date) => {
                  setShowNextVisitPicker(Platform.OS === 'ios');
                  if (date) setNextVetVisit(date);
                }}
              />
            )}
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

export default EditPetVetModal;
