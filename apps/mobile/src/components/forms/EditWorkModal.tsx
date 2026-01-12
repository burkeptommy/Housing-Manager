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
import { colors, typography, spacing } from '../../lib/theme';
import { Input } from './Input';
import { Button } from '../ui/Button';

interface WorkData {
  employer?: string | null;
  occupation?: string | null;
  workPhone?: string | null;
  workEmail?: string | null;
  workAddress?: string | null;
  workSchedule?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: WorkData) => Promise<void>;
  initialData?: WorkData;
}

export function EditWorkModal({ visible, onClose, onSave, initialData }: Props) {
  const [employer, setEmployer] = useState(initialData?.employer || '');
  const [occupation, setOccupation] = useState(initialData?.occupation || '');
  const [workPhone, setWorkPhone] = useState(initialData?.workPhone || '');
  const [workEmail, setWorkEmail] = useState(initialData?.workEmail || '');
  const [workAddress, setWorkAddress] = useState(initialData?.workAddress || '');
  const [workSchedule, setWorkSchedule] = useState(initialData?.workSchedule || '');
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setEmployer(initialData?.employer || '');
      setOccupation(initialData?.occupation || '');
      setWorkPhone(initialData?.workPhone || '');
      setWorkEmail(initialData?.workEmail || '');
      setWorkAddress(initialData?.workAddress || '');
      setWorkSchedule(initialData?.workSchedule || '');
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        employer: employer.trim() || null,
        occupation: occupation.trim() || null,
        workPhone: workPhone.trim() || null,
        workEmail: workEmail.trim() || null,
        workAddress: workAddress.trim() || null,
        workSchedule: workSchedule.trim() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save work information');
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
            <Text style={styles.title}>Work Information</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Input
              label="Employer"
              value={employer}
              onChangeText={setEmployer}
              placeholder="Company or organization name"
            />

            <Input
              label="Job Title"
              value={occupation}
              onChangeText={setOccupation}
              placeholder="Position or role"
            />

            <Input
              label="Work Phone"
              value={workPhone}
              onChangeText={setWorkPhone}
              placeholder="Office phone number"
              keyboardType="phone-pad"
            />

            <Input
              label="Work Email"
              value={workEmail}
              onChangeText={setWorkEmail}
              placeholder="Work email address"
              keyboardType="email-address"
              autoCapitalize="none"
            />

            <Input
              label="Office Address"
              value={workAddress}
              onChangeText={setWorkAddress}
              placeholder="Work location address"
              multiline
              numberOfLines={2}
            />

            <Input
              label="Work Schedule"
              value={workSchedule}
              onChangeText={setWorkSchedule}
              placeholder="e.g., Mon-Fri 9am-5pm"
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

export default EditWorkModal;
