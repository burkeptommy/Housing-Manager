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

interface AddMedicationModalProps {
  visible: boolean;
  onClose: () => void;
  petId: string;
  householdId: string;
  onSuccess: () => void;
}

const FREQUENCY_OPTIONS = [
  { id: 'once_daily', label: 'Once Daily' },
  { id: 'twice_daily', label: 'Twice Daily' },
  { id: 'three_daily', label: 'Three Times Daily' },
  { id: 'as_needed', label: 'As Needed' },
  { id: 'weekly', label: 'Weekly' },
  { id: 'monthly', label: 'Monthly' },
  { id: 'other', label: 'Other' },
];

export function AddMedicationModal({
  visible,
  onClose,
  petId,
  householdId,
  onSuccess,
}: AddMedicationModalProps) {
  const [medicationName, setMedicationName] = useState('');
  const [dosage, setDosage] = useState('');
  const [selectedFrequency, setSelectedFrequency] = useState('');
  const [customFrequency, setCustomFrequency] = useState('');
  const [prescribedBy, setPrescribedBy] = useState('');
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState('');
  const [reason, setReason] = useState('');
  const [notes, setNotes] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  const handleSave = async () => {
    if (!medicationName.trim()) {
      Alert.alert('Required', 'Medication name is required');
      return;
    }

    if (!dosage.trim()) {
      Alert.alert('Required', 'Dosage is required');
      return;
    }

    const frequency = selectedFrequency === 'other'
      ? customFrequency.trim()
      : FREQUENCY_OPTIONS.find(f => f.id === selectedFrequency)?.label;

    if (!frequency) {
      Alert.alert('Required', 'Frequency is required');
      return;
    }

    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) throw new Error('Authentication expired');

      const response = await fetch(
        `${API_BASE_URL}/family/pets/${petId}/medications`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            name: medicationName.trim(),
            dosage: dosage.trim(),
            frequency,
            prescribedBy: prescribedBy.trim() || null,
            startDate: startDate || null,
            endDate: endDate || null,
            reason: reason.trim() || null,
            notes: notes.trim() || null,
          }),
        }
      );

      if (!response.ok) throw new Error('Failed to save medication');

      onSuccess();
      onClose();

      // Reset form
      setMedicationName('');
      setDosage('');
      setSelectedFrequency('');
      setCustomFrequency('');
      setPrescribedBy('');
      setStartDate(new Date().toISOString().split('T')[0]);
      setEndDate('');
      setReason('');
      setNotes('');

      Alert.alert('Success', 'Medication added');
    } catch (err) {
      Alert.alert('Error', 'Failed to save medication');
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
            <Text style={styles.title}>Add Medication</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            {/* Medication Name */}
            <Text style={styles.label}>Medication Name *</Text>
            <TextInput
              style={styles.input}
              value={medicationName}
              onChangeText={setMedicationName}
              placeholder="e.g., Apoquel, Heartgard"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Dosage */}
            <Text style={styles.label}>Dosage *</Text>
            <TextInput
              style={styles.input}
              value={dosage}
              onChangeText={setDosage}
              placeholder="e.g., 16mg, 1 tablet, 0.5ml"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Frequency */}
            <Text style={styles.label}>Frequency *</Text>
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              style={styles.typeScroll}
              contentContainerStyle={styles.typeScrollContent}
            >
              {FREQUENCY_OPTIONS.map(freq => (
                <TouchableOpacity
                  key={freq.id}
                  style={[styles.typeChip, selectedFrequency === freq.id && styles.typeChipActive]}
                  onPress={() => setSelectedFrequency(freq.id)}
                >
                  <Text style={[
                    styles.typeChipText,
                    selectedFrequency === freq.id && styles.typeChipTextActive
                  ]}>
                    {freq.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>

            {/* Custom frequency if "Other" selected */}
            {selectedFrequency === 'other' && (
              <>
                <Text style={styles.label}>Custom Frequency *</Text>
                <TextInput
                  style={styles.input}
                  value={customFrequency}
                  onChangeText={setCustomFrequency}
                  placeholder="Enter frequency"
                  placeholderTextColor={colors.text.tertiary}
                />
              </>
            )}

            {/* Prescribed By */}
            <Text style={styles.label}>Prescribed By</Text>
            <TextInput
              style={styles.input}
              value={prescribedBy}
              onChangeText={setPrescribedBy}
              placeholder="Veterinarian name"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Start Date */}
            <Text style={styles.label}>Start Date</Text>
            <TextInput
              style={styles.input}
              value={startDate}
              onChangeText={setStartDate}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* End Date */}
            <Text style={styles.label}>End Date (if applicable)</Text>
            <TextInput
              style={styles.input}
              value={endDate}
              onChangeText={setEndDate}
              placeholder="YYYY-MM-DD or leave blank for ongoing"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Reason/Condition */}
            <Text style={styles.label}>Reason/Condition</Text>
            <TextInput
              style={styles.input}
              value={reason}
              onChangeText={setReason}
              placeholder="e.g., Allergies, Heartworm prevention"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Notes */}
            <Text style={styles.label}>Notes</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={notes}
              onChangeText={setNotes}
              placeholder="Administration instructions, side effects to watch..."
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
              title={isSaving ? 'Saving...' : 'Save Medication'}
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
    backgroundColor: colors.haven.champagne[500],
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
