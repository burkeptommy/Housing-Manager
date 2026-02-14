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

interface MedicalData {
  primaryDoctorName?: string | null;
  primaryDoctorPhone?: string | null;
  bloodType?: string | null;
  insuranceProvider?: string | null;
  insuranceMemberId?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: MedicalData) => Promise<void>;
  initialData?: MedicalData;
}

const BLOOD_TYPES = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

export function EditMedicalInfoModal({ visible, onClose, onSave, initialData }: Props) {
  const [doctorName, setDoctorName] = useState(initialData?.primaryDoctorName || '');
  const [doctorPhone, setDoctorPhone] = useState(initialData?.primaryDoctorPhone || '');
  const [bloodType, setBloodType] = useState(initialData?.bloodType || '');
  const [insuranceProvider, setInsuranceProvider] = useState(initialData?.insuranceProvider || '');
  const [insuranceMemberId, setInsuranceMemberId] = useState(initialData?.insuranceMemberId || '');
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setDoctorName(initialData?.primaryDoctorName || '');
      setDoctorPhone(initialData?.primaryDoctorPhone || '');
      setBloodType(initialData?.bloodType || '');
      setInsuranceProvider(initialData?.insuranceProvider || '');
      setInsuranceMemberId(initialData?.insuranceMemberId || '');
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        primaryDoctorName: doctorName.trim() || null,
        primaryDoctorPhone: doctorPhone.trim() || null,
        bloodType: bloodType || null,
        insuranceProvider: insuranceProvider.trim() || null,
        insuranceMemberId: insuranceMemberId.trim() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save medical information');
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
            <Text style={styles.title}>Medical Info</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Input
              label="Primary Doctor"
              value={doctorName}
              onChangeText={setDoctorName}
              placeholder="Doctor's name"
              autoCapitalize="words"
            />

            <Input
              label="Doctor's Phone"
              value={doctorPhone}
              onChangeText={setDoctorPhone}
              placeholder="(555) 123-4567"
              keyboardType="phone-pad"
            />

            <View style={styles.bloodTypeSection}>
              <Text style={styles.inputLabel}>Blood Type</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                {BLOOD_TYPES.map((type) => (
                  <TouchableOpacity
                    key={type}
                    style={[styles.bloodTypeChip, bloodType === type && styles.bloodTypeChipActive]}
                    onPress={() => setBloodType(bloodType === type ? '' : type)}
                  >
                    <Text style={[styles.bloodTypeText, bloodType === type && styles.bloodTypeTextActive]}>
                      {type}
                    </Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>

            <Input
              label="Insurance Provider"
              value={insuranceProvider}
              onChangeText={setInsuranceProvider}
              placeholder="e.g., Blue Cross, Aetna"
              autoCapitalize="words"
            />

            <Input
              label="Member ID"
              value={insuranceMemberId}
              onChangeText={setInsuranceMemberId}
              placeholder="Insurance member ID"
              autoCapitalize="characters"
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
  inputLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  bloodTypeSection: {
    marginBottom: spacing[4],
  },
  bloodTypeChip: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    backgroundColor: colors.gray[100],
    marginRight: spacing[2],
    minWidth: 50,
    alignItems: 'center',
  },
  bloodTypeChipActive: {
    backgroundColor: colors.haven.purple[500],
  },
  bloodTypeText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  bloodTypeTextActive: {
    color: colors.white,
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

export default EditMedicalInfoModal;
