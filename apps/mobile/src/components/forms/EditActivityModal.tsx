import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  ScrollView,
  TouchableOpacity,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { Input } from './Input';
import { Button } from '../ui/Button';

const ACTIVITY_TYPES = [
  { id: 'sports', label: 'Sports' },
  { id: 'music', label: 'Music' },
  { id: 'art', label: 'Art' },
  { id: 'dance', label: 'Dance' },
  { id: 'tutoring', label: 'Tutoring' },
  { id: 'camp', label: 'Camp' },
  { id: 'club', label: 'Club' },
  { id: 'other', label: 'Other' },
];

const PAYMENT_FREQUENCIES = [
  { id: 'per_session', label: 'Per Session' },
  { id: 'weekly', label: 'Weekly' },
  { id: 'monthly', label: 'Monthly' },
  { id: 'per_season', label: 'Per Season' },
];

export interface ActivityData {
  id?: string;
  name: string;
  type: string;
  location?: string | null;
  instructor?: string | null;
  schedule?: string | null;
  cost?: number | null;
  paymentFrequency?: string | null;
  notes?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: ActivityData) => Promise<void>;
  onDelete?: (id: string) => Promise<void>;
  initialData?: ActivityData | null;
  isNew?: boolean;
}

export function EditActivityModal({
  visible,
  onClose,
  onSave,
  onDelete,
  initialData,
  isNew = true
}: Props) {
  const [isSaving, setIsSaving] = useState(false);
  const [name, setName] = useState('');
  const [type, setType] = useState('sports');
  const [location, setLocation] = useState('');
  const [instructor, setInstructor] = useState('');
  const [schedule, setSchedule] = useState('');
  const [cost, setCost] = useState('');
  const [paymentFrequency, setPaymentFrequency] = useState('monthly');
  const [notes, setNotes] = useState('');

  useEffect(() => {
    if (visible) {
      setName(initialData?.name || '');
      setType(initialData?.type || 'sports');
      setLocation(initialData?.location || '');
      setInstructor(initialData?.instructor || '');
      setSchedule(initialData?.schedule || '');
      setCost(initialData?.cost?.toString() || '');
      setPaymentFrequency(initialData?.paymentFrequency || 'monthly');
      setNotes(initialData?.notes || '');
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert('Required', 'Activity name is required');
      return;
    }

    setIsSaving(true);
    try {
      await onSave({
        id: initialData?.id,
        name: name.trim(),
        type,
        location: location.trim() || null,
        instructor: instructor.trim() || null,
        schedule: schedule.trim() || null,
        cost: cost ? parseFloat(cost) : null,
        paymentFrequency: paymentFrequency || null,
        notes: notes.trim() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save activity');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = () => {
    if (!initialData?.id || !onDelete) return;

    Alert.alert(
      'Remove Activity',
      `Are you sure you want to remove "${name}"?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              await onDelete(initialData.id!);
              onClose();
            } catch (err) {
              Alert.alert('Error', 'Failed to remove activity');
            }
          },
        },
      ]
    );
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
            <Text style={styles.title}>{isNew ? 'Add Activity' : 'Edit Activity'}</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Input
              label="Activity Name *"
              value={name}
              onChangeText={setName}
              placeholder="e.g., Soccer, Piano Lessons"
            />

            {/* Type Selection */}
            <Text style={styles.label}>Type</Text>
            <View style={styles.typeGrid}>
              {ACTIVITY_TYPES.map((t) => (
                <TouchableOpacity
                  key={t.id}
                  style={[
                    styles.typeItem,
                    type === t.id && styles.typeItemSelected,
                  ]}
                  onPress={() => setType(t.id)}
                >
                  <Text
                    style={[
                      styles.typeLabel,
                      type === t.id && styles.typeLabelSelected,
                    ]}
                  >
                    {t.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Input
              label="Location/Venue"
              value={location}
              onChangeText={setLocation}
              placeholder="Where does this take place?"
            />

            <Input
              label="Instructor/Coach"
              value={instructor}
              onChangeText={setInstructor}
              placeholder="Instructor name"
            />

            <Input
              label="Schedule"
              value={schedule}
              onChangeText={setSchedule}
              placeholder="e.g., Tuesdays 4-5pm"
            />

            <Input
              label="Cost"
              value={cost}
              onChangeText={setCost}
              placeholder="0.00"
              keyboardType="decimal-pad"
            />

            {/* Payment Frequency */}
            <Text style={styles.label}>Payment Frequency</Text>
            <View style={styles.frequencyRow}>
              {PAYMENT_FREQUENCIES.map((freq) => (
                <TouchableOpacity
                  key={freq.id}
                  style={[
                    styles.frequencyItem,
                    paymentFrequency === freq.id && styles.frequencyItemSelected,
                  ]}
                  onPress={() => setPaymentFrequency(freq.id)}
                >
                  <Text
                    style={[
                      styles.frequencyLabel,
                      paymentFrequency === freq.id && styles.frequencyLabelSelected,
                    ]}
                  >
                    {freq.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Input
              label="Notes"
              value={notes}
              onChangeText={setNotes}
              placeholder="Any additional notes..."
              multiline
              numberOfLines={3}
            />

            {/* Delete Button (if editing existing) */}
            {!isNew && onDelete && initialData?.id && (
              <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
                <Ionicons name="trash-outline" size={20} color={colors.status.error} />
                <Text style={styles.deleteButtonText}>Remove Activity</Text>
              </TouchableOpacity>
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
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
    marginTop: spacing[3],
  },
  typeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  typeItem: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
  },
  typeItemSelected: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.haven.champagne[50],
  },
  typeLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  typeLabelSelected: {
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  frequencyRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  frequencyItem: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
  },
  frequencyItemSelected: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.haven.champagne[50],
  },
  frequencyLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
  },
  frequencyLabelSelected: {
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[4],
    marginTop: spacing[4],
  },
  deleteButtonText: {
    fontSize: typography.fontSizes.base,
    color: colors.status.error,
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

export default EditActivityModal;
