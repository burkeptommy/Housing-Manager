import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  TextInput,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Button } from '../ui/Button';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';

interface EditPetIdModalProps {
  visible: boolean;
  onClose: () => void;
  onSave: (data: {
    microchipId?: string | null;
    licenseNumber?: string | null;
    licenseExpires?: string | null;
    registryName?: string | null;
    registryPhone?: string | null;
  }) => Promise<void>;
  initialData: {
    microchipId?: string | null;
    licenseNumber?: string | null;
    licenseExpires?: string | null;
    registryName?: string | null;
    registryPhone?: string | null;
  };
}

export function EditPetIdModal({
  visible,
  onClose,
  onSave,
  initialData,
}: EditPetIdModalProps) {
  const [microchipId, setMicrochipId] = useState('');
  const [licenseNumber, setLicenseNumber] = useState('');
  const [licenseExpires, setLicenseExpires] = useState('');
  const [registryName, setRegistryName] = useState('');
  const [registryPhone, setRegistryPhone] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setMicrochipId(initialData.microchipId || '');
      setLicenseNumber(initialData.licenseNumber || '');
      setLicenseExpires(initialData.licenseExpires?.split('T')[0] || '');
      setRegistryName(initialData.registryName || '');
      setRegistryPhone(initialData.registryPhone || '');
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        microchipId: microchipId.trim() || null,
        licenseNumber: licenseNumber.trim() || null,
        licenseExpires: licenseExpires || null,
        registryName: registryName.trim() || null,
        registryPhone: registryPhone.trim() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save ID information');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboard}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>IDs & Registration</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            {/* Microchip Section */}
            <View style={styles.sectionHeader}>
              <Ionicons name="qr-code-outline" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.sectionTitle}>Microchip</Text>
            </View>
            <Text style={styles.sectionDescription}>
              A microchip is a permanent ID that helps reunite lost pets with their owners.
            </Text>

            <Text style={styles.label}>Microchip ID Number</Text>
            <TextInput
              style={styles.input}
              value={microchipId}
              onChangeText={setMicrochipId}
              placeholder="e.g., 985121012345678"
              placeholderTextColor={colors.text.tertiary}
              autoCapitalize="characters"
            />

            <Text style={styles.label}>Microchip Registry</Text>
            <TextInput
              style={styles.input}
              value={registryName}
              onChangeText={setRegistryName}
              placeholder="e.g., HomeAgain, Found Animals"
              placeholderTextColor={colors.text.tertiary}
            />

            <Text style={styles.label}>Registry Phone</Text>
            <TextInput
              style={styles.input}
              value={registryPhone}
              onChangeText={setRegistryPhone}
              placeholder="(555) 123-4567"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="phone-pad"
            />

            {/* License Section */}
            <View style={[styles.sectionHeader, { marginTop: spacing[6] }]}>
              <Ionicons name="card-outline" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.sectionTitle}>License</Text>
            </View>
            <Text style={styles.sectionDescription}>
              Most cities require pets to be licensed. Keep this info handy for renewals.
            </Text>

            <Text style={styles.label}>License Number</Text>
            <TextInput
              style={styles.input}
              value={licenseNumber}
              onChangeText={setLicenseNumber}
              placeholder="e.g., DOG-2024-123456"
              placeholderTextColor={colors.text.tertiary}
              autoCapitalize="characters"
            />

            <Text style={styles.label}>License Expiration Date</Text>
            <TextInput
              style={styles.input}
              value={licenseExpires}
              onChangeText={setLicenseExpires}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={colors.text.tertiary}
            />

            <View style={styles.tipBox}>
              <Ionicons name="bulb-outline" size={18} color={colors.haven.navy[600]} />
              <Text style={styles.tipText}>
                Haven will remind you when your pet's license is about to expire.
              </Text>
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
              title={isSaving ? 'Saving...' : 'Save'}
              onPress={handleSave}
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
  keyboard: {
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
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  sectionDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[4],
    lineHeight: 20,
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[2],
    marginTop: spacing[3],
  },
  input: {
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  tipBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[2],
    padding: spacing[3],
    backgroundColor: colors.haven.navy[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
  },
  tipText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[700],
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
