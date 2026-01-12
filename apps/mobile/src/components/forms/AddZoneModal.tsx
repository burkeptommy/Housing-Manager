import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  ScrollView,
  TextInput,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { API_BASE_URL } from '../../lib/api';
import { getIdToken } from '../../lib/firebase';
import { Button } from '../ui/Button';

// =============================================================================
// TYPES
// =============================================================================

type ZoneType =
  | 'KITCHEN' | 'LIVING_ROOM' | 'DINING_ROOM' | 'BEDROOM' | 'BATHROOM'
  | 'GARAGE' | 'BASEMENT' | 'ATTIC' | 'LAUNDRY' | 'OFFICE' | 'MUDROOM'
  | 'PANTRY' | 'OUTDOOR_FRONT' | 'OUTDOOR_BACK' | 'POOL_AREA' | 'MECHANICAL' | 'OTHER';

interface AddZoneModalProps {
  visible: boolean;
  onClose: () => void;
  householdId: string;
  onSuccess: () => void;
}

// =============================================================================
// COMPONENT
// =============================================================================

const ZONE_TYPES: { value: ZoneType; label: string; icon: keyof typeof Ionicons.glyphMap }[] = [
  { value: 'KITCHEN', label: 'Kitchen', icon: 'restaurant-outline' },
  { value: 'LIVING_ROOM', label: 'Living Room', icon: 'tv-outline' },
  { value: 'DINING_ROOM', label: 'Dining Room', icon: 'cafe-outline' },
  { value: 'BEDROOM', label: 'Bedroom', icon: 'bed-outline' },
  { value: 'BATHROOM', label: 'Bathroom', icon: 'water-outline' },
  { value: 'GARAGE', label: 'Garage', icon: 'car-outline' },
  { value: 'BASEMENT', label: 'Basement', icon: 'layers-outline' },
  { value: 'ATTIC', label: 'Attic', icon: 'home-outline' },
  { value: 'LAUNDRY', label: 'Laundry', icon: 'shirt-outline' },
  { value: 'OFFICE', label: 'Office', icon: 'desktop-outline' },
  { value: 'MUDROOM', label: 'Mudroom', icon: 'footsteps-outline' },
  { value: 'PANTRY', label: 'Pantry', icon: 'fast-food-outline' },
  { value: 'OUTDOOR_FRONT', label: 'Front Yard', icon: 'leaf-outline' },
  { value: 'OUTDOOR_BACK', label: 'Back Yard', icon: 'flower-outline' },
  { value: 'POOL_AREA', label: 'Pool Area', icon: 'water-outline' },
  { value: 'MECHANICAL', label: 'Mechanical', icon: 'construct-outline' },
  { value: 'OTHER', label: 'Other', icon: 'cube-outline' },
];

export function AddZoneModal({
  visible,
  onClose,
  householdId,
  onSuccess,
}: AddZoneModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [name, setName] = useState('');
  const [type, setType] = useState<ZoneType>('LIVING_ROOM');
  const [floor, setFloor] = useState('');
  const [notes, setNotes] = useState('');
  const [procedures, setProcedures] = useState('');

  const resetForm = () => {
    setName('');
    setType('LIVING_ROOM');
    setFloor('');
    setNotes('');
    setProcedures('');
    setError(null);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleSubmit = async () => {
    if (!name.trim()) {
      setError('Zone name is required');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/property/zones/household/${householdId}`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            name: name.trim(),
            type,
            floor: floor.trim() || undefined,
            notes: notes.trim() || undefined,
            procedures: procedures.trim() || undefined,
          }),
        }
      );

      if (!response.ok) {
        throw new Error('Failed to add zone');
      }

      handleClose();
      onSuccess();
    } catch (err) {
      console.error('Add zone error:', err);
      setError('Failed to add zone. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={handleClose}
    >
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={handleClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Add Zone</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Zone Name */}
            <View style={styles.section}>
              <Text style={styles.label}>Zone Name *</Text>
              <TextInput
                style={styles.input}
                value={name}
                onChangeText={setName}
                placeholder="e.g., Master Bedroom, Kitchen"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Zone Type */}
            <View style={styles.section}>
              <Text style={styles.label}>Zone Type</Text>
              <View style={styles.typeGrid}>
                {ZONE_TYPES.map((zt) => (
                  <TouchableOpacity
                    key={zt.value}
                    style={[
                      styles.typeButton,
                      type === zt.value && styles.typeButtonActive,
                    ]}
                    onPress={() => setType(zt.value)}
                  >
                    <Ionicons
                      name={zt.icon}
                      size={18}
                      color={type === zt.value ? colors.haven.champagne[600] : colors.text.tertiary}
                    />
                    <Text
                      style={[
                        styles.typeButtonText,
                        type === zt.value && styles.typeButtonTextActive,
                      ]}
                    >
                      {zt.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Floor */}
            <View style={styles.section}>
              <Text style={styles.label}>Floor</Text>
              <TextInput
                style={styles.input}
                value={floor}
                onChangeText={setFloor}
                placeholder="e.g., 1st Floor, Basement"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Notes */}
            <View style={styles.section}>
              <Text style={styles.label}>Notes</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                value={notes}
                onChangeText={setNotes}
                placeholder="Any notes about this zone..."
                placeholderTextColor={colors.text.tertiary}
                multiline
                numberOfLines={3}
                textAlignVertical="top"
              />
            </View>

            {/* Procedures */}
            <View style={styles.section}>
              <Text style={styles.label}>Care Instructions</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                value={procedures}
                onChangeText={setProcedures}
                placeholder="How to care for this zone..."
                placeholderTextColor={colors.text.tertiary}
                multiline
                numberOfLines={3}
                textAlignVertical="top"
              />
            </View>

            {/* Error */}
            {error && (
              <View style={styles.errorContainer}>
                <Text style={styles.errorText}>{error}</Text>
              </View>
            )}

            {/* Submit Button */}
            <View style={styles.buttonContainer}>
              <Button
                title={isSubmitting ? 'Adding...' : 'Add Zone'}
                onPress={handleSubmit}
                disabled={isSubmitting || !name.trim()}
                variant="primary"
              />
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

// =============================================================================
// STYLES
// =============================================================================

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
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  placeholder: {
    width: 40,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  section: {
    marginBottom: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
  },
  input: {
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  textArea: {
    minHeight: 80,
    paddingTop: spacing[3],
  },
  typeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  typeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.background.secondary,
    borderWidth: 1,
    borderColor: colors.border.light,
    gap: spacing[1],
  },
  typeButtonActive: {
    backgroundColor: colors.haven.champagne[50],
    borderColor: colors.haven.champagne[500],
  },
  typeButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  typeButtonTextActive: {
    color: colors.haven.champagne[600],
  },
  errorContainer: {
    backgroundColor: colors.status.error + '20',
    padding: spacing[3],
    borderRadius: borderRadius.md,
    marginBottom: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.status.error,
    textAlign: 'center',
  },
  buttonContainer: {
    marginTop: spacing[4],
  },
});
