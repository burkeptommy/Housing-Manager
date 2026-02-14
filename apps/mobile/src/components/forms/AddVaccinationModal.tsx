import React, { useState } from 'react';
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
import { API_BASE_URL } from '../../lib/api';
import { getIdToken } from '../../lib/firebase';

interface AddVaccinationModalProps {
  visible: boolean;
  onClose: () => void;
  petId: string;
  householdId: string;
  onSuccess: () => void;
}

const COMMON_VACCINATIONS = [
  { id: 'rabies', label: 'Rabies' },
  { id: 'distemper', label: 'Distemper/Parvo (DHPP)' },
  { id: 'bordetella', label: 'Bordetella (Kennel Cough)' },
  { id: 'leptospirosis', label: 'Leptospirosis' },
  { id: 'lyme', label: 'Lyme Disease' },
  { id: 'fvrcp', label: 'FVRCP (Cats)' },
  { id: 'felv', label: 'Feline Leukemia (FeLV)' },
  { id: 'other', label: 'Other' },
];

export function AddVaccinationModal({
  visible,
  onClose,
  petId,
  householdId,
  onSuccess,
}: AddVaccinationModalProps) {
  const [selectedType, setSelectedType] = useState('');
  const [customName, setCustomName] = useState('');
  const [givenDate, setGivenDate] = useState(new Date().toISOString().split('T')[0]);
  const [expiresAt, setExpiresAt] = useState('');
  const [vetName, setVetName] = useState('');
  const [batchNumber, setBatchNumber] = useState('');
  const [notes, setNotes] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  const handleSave = async () => {
    const vaccineName = selectedType === 'other'
      ? customName.trim()
      : COMMON_VACCINATIONS.find(v => v.id === selectedType)?.label;

    if (!vaccineName) {
      Alert.alert('Required', 'Please select or enter a vaccination name');
      return;
    }

    if (!givenDate) {
      Alert.alert('Required', 'Vaccination date is required');
      return;
    }

    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) throw new Error('Authentication expired');

      const response = await fetch(
        `${API_BASE_URL}/family/pets/${petId}/vaccinations`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            name: vaccineName,
            date: givenDate,
            expiresAt: expiresAt || null,
            veterinarian: vetName || null,
            batchNumber: batchNumber || null,
            notes: notes || null,
          }),
        }
      );

      if (!response.ok) throw new Error('Failed to save vaccination');

      onSuccess();
      onClose();

      // Reset form
      setSelectedType('');
      setCustomName('');
      setGivenDate(new Date().toISOString().split('T')[0]);
      setExpiresAt('');
      setVetName('');
      setBatchNumber('');
      setNotes('');

      Alert.alert('Success', 'Vaccination record added');
    } catch (err) {
      Alert.alert('Error', 'Failed to save vaccination record');
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
            <Text style={styles.title}>Add Vaccination</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            {/* Vaccination Type */}
            <Text style={styles.label}>Vaccination Type *</Text>
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              style={styles.typeScroll}
              contentContainerStyle={styles.typeScrollContent}
            >
              {COMMON_VACCINATIONS.map(vax => (
                <TouchableOpacity
                  key={vax.id}
                  style={[styles.typeChip, selectedType === vax.id && styles.typeChipActive]}
                  onPress={() => setSelectedType(vax.id)}
                >
                  <Text style={[
                    styles.typeChipText,
                    selectedType === vax.id && styles.typeChipTextActive
                  ]}>
                    {vax.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>

            {/* Custom name if "Other" selected */}
            {selectedType === 'other' && (
              <>
                <Text style={styles.label}>Vaccination Name *</Text>
                <TextInput
                  style={styles.input}
                  value={customName}
                  onChangeText={setCustomName}
                  placeholder="Enter vaccination name"
                  placeholderTextColor={colors.text.tertiary}
                />
              </>
            )}

            {/* Date Given */}
            <Text style={styles.label}>Date Given *</Text>
            <TextInput
              style={styles.input}
              value={givenDate}
              onChangeText={setGivenDate}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Expiration Date */}
            <Text style={styles.label}>Expiration Date</Text>
            <TextInput
              style={styles.input}
              value={expiresAt}
              onChangeText={setExpiresAt}
              placeholder="YYYY-MM-DD (if applicable)"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Administering Vet */}
            <Text style={styles.label}>Administering Veterinarian</Text>
            <TextInput
              style={styles.input}
              value={vetName}
              onChangeText={setVetName}
              placeholder="e.g., Dr. Smith"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Batch/Lot Number */}
            <Text style={styles.label}>Batch/Lot Number</Text>
            <TextInput
              style={styles.input}
              value={batchNumber}
              onChangeText={setBatchNumber}
              placeholder="For your records"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Notes */}
            <Text style={styles.label}>Notes</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={notes}
              onChangeText={setNotes}
              placeholder="Any reactions or additional notes..."
              placeholderTextColor={colors.text.tertiary}
              multiline
              numberOfLines={3}
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
              title={isSaving ? 'Saving...' : 'Save Vaccination'}
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
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[2],
    marginTop: spacing[4],
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
  textArea: {
    minHeight: 80,
    textAlignVertical: 'top',
  },
  typeScroll: {
    marginHorizontal: -spacing[4],
  },
  typeScrollContent: {
    paddingHorizontal: spacing[4],
    gap: spacing[2],
  },
  typeChip: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    backgroundColor: colors.gray[100],
    marginRight: spacing[2],
  },
  typeChipActive: {
    backgroundColor: colors.haven.purple[500],
  },
  typeChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  typeChipTextActive: {
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
