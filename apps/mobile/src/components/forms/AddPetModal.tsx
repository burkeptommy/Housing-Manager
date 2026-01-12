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

type PetType = 'DOG' | 'CAT' | 'BIRD' | 'FISH' | 'REPTILE' | 'OTHER';

interface AddPetModalProps {
  visible: boolean;
  onClose: () => void;
  householdId: string;
  onSuccess: () => void;
}

// =============================================================================
// COMPONENT
// =============================================================================

export function AddPetModal({
  visible,
  onClose,
  householdId,
  onSuccess,
}: AddPetModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [name, setName] = useState('');
  const [type, setType] = useState<PetType>('DOG');
  const [breed, setBreed] = useState('');
  const [color, setColor] = useState('');

  // Vet info
  const [vetClinicName, setVetClinicName] = useState('');
  const [vetClinicPhone, setVetClinicPhone] = useState('');

  // Food info
  const [foodBrand, setFoodBrand] = useState('');
  const [feedingSchedule, setFeedingSchedule] = useState('');

  const resetForm = () => {
    setName('');
    setType('DOG');
    setBreed('');
    setColor('');
    setVetClinicName('');
    setVetClinicPhone('');
    setFoodBrand('');
    setFeedingSchedule('');
    setError(null);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleSubmit = async () => {
    if (!name.trim()) {
      setError('Pet name is required');
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

      const response = await fetch(`${API_BASE_URL}/family/pets`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: name.trim(),
          type,
          breed: breed.trim() || undefined,
          color: color.trim() || undefined,
          vetClinicName: vetClinicName.trim() || undefined,
          vetClinicPhone: vetClinicPhone.trim() || undefined,
          foodBrand: foodBrand.trim() || undefined,
          feedingSchedule: feedingSchedule.trim() || undefined,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to add pet');
      }

      handleClose();
      onSuccess();
    } catch (err) {
      console.error('Add pet error:', err);
      setError('Failed to add pet. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const petTypes: { value: PetType; label: string; icon: string }[] = [
    { value: 'DOG', label: 'Dog', icon: 'paw' },
    { value: 'CAT', label: 'Cat', icon: 'paw' },
    { value: 'BIRD', label: 'Bird', icon: 'leaf' },
    { value: 'FISH', label: 'Fish', icon: 'fish' },
    { value: 'REPTILE', label: 'Reptile', icon: 'leaf' },
    { value: 'OTHER', label: 'Other', icon: 'ellipsis-horizontal' },
  ];

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
            <Text style={styles.title}>Add Pet</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Pet Type */}
            <View style={styles.section}>
              <Text style={styles.label}>Pet Type</Text>
              <View style={styles.typeGrid}>
                {petTypes.map((pt) => (
                  <TouchableOpacity
                    key={pt.value}
                    style={[styles.typeButton, type === pt.value && styles.typeButtonActive]}
                    onPress={() => setType(pt.value)}
                  >
                    <Ionicons
                      name={pt.icon as any}
                      size={20}
                      color={type === pt.value ? colors.haven.champagne[600] : colors.text.tertiary}
                    />
                    <Text style={[styles.typeButtonText, type === pt.value && styles.typeButtonTextActive]}>
                      {pt.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Basic Info */}
            <View style={styles.section}>
              <Text style={styles.label}>Name *</Text>
              <TextInput
                style={styles.input}
                value={name}
                onChangeText={setName}
                placeholder="Enter pet's name"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Breed</Text>
              <TextInput
                style={styles.input}
                value={breed}
                onChangeText={setBreed}
                placeholder="e.g., Golden Retriever, Siamese"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Color</Text>
              <TextInput
                style={styles.input}
                value={color}
                onChangeText={setColor}
                placeholder="e.g., Brown, Black & White"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Vet Info */}
            <View style={styles.sectionDivider}>
              <Text style={styles.sectionTitle}>Veterinarian</Text>
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Vet Clinic Name</Text>
              <TextInput
                style={styles.input}
                value={vetClinicName}
                onChangeText={setVetClinicName}
                placeholder="Enter clinic name"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Vet Phone</Text>
              <TextInput
                style={styles.input}
                value={vetClinicPhone}
                onChangeText={setVetClinicPhone}
                placeholder="Enter phone number"
                placeholderTextColor={colors.text.tertiary}
                keyboardType="phone-pad"
              />
            </View>

            {/* Food Info */}
            <View style={styles.sectionDivider}>
              <Text style={styles.sectionTitle}>Feeding</Text>
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Food Brand</Text>
              <TextInput
                style={styles.input}
                value={foodBrand}
                onChangeText={setFoodBrand}
                placeholder="Enter food brand"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Feeding Schedule</Text>
              <TextInput
                style={styles.input}
                value={feedingSchedule}
                onChangeText={setFeedingSchedule}
                placeholder="e.g., 8am and 6pm, 1 cup each"
                placeholderTextColor={colors.text.tertiary}
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
                title={isSubmitting ? 'Adding...' : 'Add Pet'}
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
  sectionDivider: {
    marginTop: spacing[4],
    marginBottom: spacing[4],
    paddingBottom: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
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
