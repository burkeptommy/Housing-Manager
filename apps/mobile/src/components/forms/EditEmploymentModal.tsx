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

interface EmploymentData {
  agencyName?: string | null;
  agencyContact?: string | null;
  agencyPhone?: string | null;
  responsibilities?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: EmploymentData) => Promise<void>;
  initialData?: EmploymentData;
}

export function EditEmploymentModal({ visible, onClose, onSave, initialData }: Props) {
  const [agencyName, setAgencyName] = useState(initialData?.agencyName || '');
  const [agencyContact, setAgencyContact] = useState(initialData?.agencyContact || '');
  const [agencyPhone, setAgencyPhone] = useState(initialData?.agencyPhone || '');
  const [responsibilities, setResponsibilities] = useState(initialData?.responsibilities || '');
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setAgencyName(initialData?.agencyName || '');
      setAgencyContact(initialData?.agencyContact || '');
      setAgencyPhone(initialData?.agencyPhone || '');
      setResponsibilities(initialData?.responsibilities || '');
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        agencyName: agencyName.trim() || null,
        agencyContact: agencyContact.trim() || null,
        agencyPhone: agencyPhone.trim() || null,
        responsibilities: responsibilities.trim() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save employment info');
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
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Employment Details</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Text style={styles.sectionLabel}>STAFFING AGENCY</Text>
            <Text style={styles.sectionDescription}>
              If this staff member is placed through an agency, add their details here.
            </Text>

            <Input
              label="Agency Name"
              value={agencyName}
              onChangeText={setAgencyName}
              placeholder="e.g., Care.com, Agency XYZ"
              autoCapitalize="words"
            />

            <Input
              label="Agency Contact Person"
              value={agencyContact}
              onChangeText={setAgencyContact}
              placeholder="Contact name at agency"
              autoCapitalize="words"
            />

            <Input
              label="Agency Phone"
              value={agencyPhone}
              onChangeText={setAgencyPhone}
              placeholder="(555) 123-4567"
              keyboardType="phone-pad"
            />

            <Text style={[styles.sectionLabel, { marginTop: spacing[5] }]}>RESPONSIBILITIES</Text>
            <Text style={styles.sectionDescription}>
              Describe this staff member's key responsibilities and duties.
            </Text>

            <Input
              value={responsibilities}
              onChangeText={setResponsibilities}
              placeholder="e.g., Childcare for 2 kids, school pickup, meal prep, light housekeeping..."
              multiline
              numberOfLines={5}
            />
          </ScrollView>

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
    marginBottom: spacing[2],
  },
  sectionDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[4],
    lineHeight: 20,
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

export default EditEmploymentModal;
