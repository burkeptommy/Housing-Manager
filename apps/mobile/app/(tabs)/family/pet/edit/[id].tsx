import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, useLocalSearchParams, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useAuth } from '../../../../../src/contexts/auth-context';
import { Card, Button, Input, LoadingSpinner, ImageUpload } from '../../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../../src/lib/api';
import { getIdToken } from '../../../../../src/lib/firebase';

interface Pet {
  id: string;
  name: string;
  type: string;
  breed?: string;
  color?: string;
  birthDate?: string;
  weight?: number;
  microchipId?: string;
  notes?: string;
  imageUrl?: string;
  // Care fields
  foodBrand?: string;
  foodType?: string;
  feedingSchedule?: string;
  feedingAmount?: string;
  // Vet fields
  vetName?: string;
  vetPhone?: string;
  vetClinic?: string;
  // Medical
  allergies?: string;
  medications?: string;
}

const PET_TYPES = ['Dog', 'Cat', 'Bird', 'Fish', 'Rabbit', 'Hamster', 'Reptile', 'Other'];

export default function EditPetScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [showBirthdayPicker, setShowBirthdayPicker] = useState(false);
  const [petImage, setPetImage] = useState<string | null>(null);

  const [formData, setFormData] = useState({
    name: '',
    type: 'Dog',
    breed: '',
    color: '',
    birthDate: null as Date | null,
    weight: '',
    microchipId: '',
    notes: '',
    // Care fields
    foodBrand: '',
    foodType: '',
    feedingSchedule: '',
    feedingAmount: '',
    // Vet fields
    vetName: '',
    vetPhone: '',
    vetClinic: '',
    // Medical
    allergies: '',
    medications: '',
  });

  const fetchPet = useCallback(async () => {
    if (!id || !householdInfo?.id) {
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setIsLoading(false);
        return;
      }

      const response = await fetch(`${API_BASE_URL}/family/household/${householdInfo.id}/pet/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const pet: Pet = await response.json();
        setFormData({
          name: pet.name || '',
          type: pet.type || 'Dog',
          breed: pet.breed || '',
          color: pet.color || '',
          birthDate: pet.birthDate ? new Date(pet.birthDate) : null,
          weight: pet.weight?.toString() || '',
          microchipId: pet.microchipId || '',
          notes: pet.notes || '',
          foodBrand: pet.foodBrand || '',
          foodType: pet.foodType || '',
          feedingSchedule: pet.feedingSchedule || '',
          feedingAmount: pet.feedingAmount || '',
          vetName: pet.vetName || '',
          vetPhone: pet.vetPhone || '',
          vetClinic: pet.vetClinic || '',
          allergies: pet.allergies || '',
          medications: pet.medications || '',
        });
        setPetImage(pet.imageUrl || null);
      }
    } catch (err) {
      console.error('Fetch pet error:', err);
    } finally {
      setIsLoading(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchPet();
  }, [fetchPet]);

  const handleSave = async () => {
    if (!formData.name.trim()) {
      Alert.alert('Required', 'Pet name is required');
      return;
    }

    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) {
        Alert.alert('Error', 'Authentication expired');
        return;
      }

      const body = {
        name: formData.name.trim(),
        type: formData.type,
        breed: formData.breed.trim() || null,
        color: formData.color.trim() || null,
        birthDate: formData.birthDate?.toISOString() || null,
        weight: formData.weight ? parseFloat(formData.weight) : null,
        microchipId: formData.microchipId.trim() || null,
        notes: formData.notes.trim() || null,
        imageUrl: petImage,
        foodBrand: formData.foodBrand.trim() || null,
        foodType: formData.foodType.trim() || null,
        feedingSchedule: formData.feedingSchedule.trim() || null,
        feedingAmount: formData.feedingAmount.trim() || null,
        vetName: formData.vetName.trim() || null,
        vetPhone: formData.vetPhone.trim() || null,
        vetClinic: formData.vetClinic.trim() || null,
        allergies: formData.allergies.trim() || null,
        medications: formData.medications.trim() || null,
      };

      const response = await fetch(`${API_BASE_URL}/family/household/${householdInfo?.id}/pet/${id}`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (!response.ok && response.status !== 404) {
        throw new Error('Failed to update pet');
      }

      Alert.alert('Success', 'Pet updated successfully', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (error) {
      console.error('Update pet error:', error);
      Alert.alert('Error', 'Failed to update pet. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = () => {
    Alert.alert(
      'Remove Pet',
      'Are you sure you want to remove this pet? This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) return;

              await fetch(`${API_BASE_URL}/family/household/${householdInfo?.id}/pet/${id}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` },
              });

              router.back();
            } catch (err) {
              console.error('Delete pet error:', err);
              Alert.alert('Error', 'Failed to remove pet');
            }
          },
        },
      ]
    );
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: 'Edit Pet', headerBackTitle: 'Back' }} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Pet Photo */}
          <View style={styles.photoSection}>
            <ImageUpload
              currentImage={petImage}
              onImageSelected={setPetImage}
              shape="circle"
              size="large"
              placeholder="Add Pet Photo"
            />
          </View>

          {/* Basic Info */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Basic Information</Text>

            <Input
              label="Name"
              value={formData.name}
              onChangeText={(v) => setFormData({ ...formData, name: v })}
              placeholder="Pet's name"
              autoCapitalize="words"
            />

            <View style={styles.typeSelector}>
              <Text style={styles.typeLabel}>Type</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                {PET_TYPES.map((type) => (
                  <TouchableOpacity
                    key={type}
                    style={[styles.typeChip, formData.type === type && styles.typeChipActive]}
                    onPress={() => setFormData({ ...formData, type })}
                  >
                    <Text style={[styles.typeChipText, formData.type === type && styles.typeChipTextActive]}>
                      {type}
                    </Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>

            <View style={styles.row}>
              <View style={styles.halfInput}>
                <Input
                  label="Breed"
                  value={formData.breed}
                  onChangeText={(v) => setFormData({ ...formData, breed: v })}
                  placeholder="e.g., Golden Retriever"
                  autoCapitalize="words"
                />
              </View>
              <View style={styles.halfInput}>
                <Input
                  label="Color"
                  value={formData.color}
                  onChangeText={(v) => setFormData({ ...formData, color: v })}
                  placeholder="e.g., Golden"
                  autoCapitalize="words"
                />
              </View>
            </View>

            <View style={styles.row}>
              <View style={styles.halfInput}>
                <Input
                  label="Weight (lbs)"
                  value={formData.weight}
                  onChangeText={(v) => setFormData({ ...formData, weight: v.replace(/[^0-9.]/g, '') })}
                  keyboardType="decimal-pad"
                  placeholder="e.g., 65"
                />
              </View>
              <View style={styles.halfInput}>
                <TouchableOpacity
                  style={styles.dateButton}
                  onPress={() => setShowBirthdayPicker(true)}
                >
                  <View style={styles.dateContent}>
                    <Text style={styles.dateLabel}>Birthday</Text>
                    <Text style={styles.dateValue}>
                      {formData.birthDate
                        ? formData.birthDate.toLocaleDateString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            year: 'numeric',
                          })
                        : 'Not set'}
                    </Text>
                  </View>
                  <Ionicons name="calendar-outline" size={20} color={colors.text.tertiary} />
                </TouchableOpacity>
              </View>
            </View>

            {showBirthdayPicker && (
              <DateTimePicker
                value={formData.birthDate || new Date()}
                mode="date"
                display="spinner"
                maximumDate={new Date()}
                onChange={(_: any, date?: Date) => {
                  setShowBirthdayPicker(Platform.OS === 'ios');
                  if (date) setFormData({ ...formData, birthDate: date });
                }}
              />
            )}

            <Input
              label="Microchip ID"
              value={formData.microchipId}
              onChangeText={(v) => setFormData({ ...formData, microchipId: v })}
              placeholder="Microchip number"
            />
          </Card>

          {/* Food & Feeding */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Food & Feeding</Text>
            <Text style={styles.cardSubtitle}>Track your pet's diet and feeding schedule</Text>

            <Input
              label="Food Brand"
              value={formData.foodBrand}
              onChangeText={(v) => setFormData({ ...formData, foodBrand: v })}
              placeholder="e.g., Blue Buffalo, Royal Canin"
              autoCapitalize="words"
            />

            <Input
              label="Food Type"
              value={formData.foodType}
              onChangeText={(v) => setFormData({ ...formData, foodType: v })}
              placeholder="e.g., Dry kibble, Wet food, Raw"
              autoCapitalize="sentences"
            />

            <Input
              label="Feeding Amount"
              value={formData.feedingAmount}
              onChangeText={(v) => setFormData({ ...formData, feedingAmount: v })}
              placeholder="e.g., 2 cups, 1 can"
            />

            <Input
              label="Feeding Schedule"
              value={formData.feedingSchedule}
              onChangeText={(v) => setFormData({ ...formData, feedingSchedule: v })}
              placeholder="e.g., 7am and 6pm, Twice daily"
            />
          </Card>

          {/* Veterinarian */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Veterinarian</Text>

            <Input
              label="Clinic Name"
              value={formData.vetClinic}
              onChangeText={(v) => setFormData({ ...formData, vetClinic: v })}
              placeholder="e.g., Happy Paws Animal Hospital"
              autoCapitalize="words"
            />

            <Input
              label="Vet Name"
              value={formData.vetName}
              onChangeText={(v) => setFormData({ ...formData, vetName: v })}
              placeholder="e.g., Dr. Smith"
              autoCapitalize="words"
            />

            <Input
              label="Phone"
              value={formData.vetPhone}
              onChangeText={(v) => setFormData({ ...formData, vetPhone: v })}
              placeholder="(555) 123-4567"
              keyboardType="phone-pad"
            />
          </Card>

          {/* Medical */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Medical Information</Text>

            <Input
              label="Allergies"
              value={formData.allergies}
              onChangeText={(v) => setFormData({ ...formData, allergies: v })}
              placeholder="List any known allergies"
              multiline
              numberOfLines={2}
            />

            <Input
              label="Medications"
              value={formData.medications}
              onChangeText={(v) => setFormData({ ...formData, medications: v })}
              placeholder="Current medications"
              multiline
              numberOfLines={2}
            />
          </Card>

          {/* Notes */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Notes</Text>
            <Input
              value={formData.notes}
              onChangeText={(v) => setFormData({ ...formData, notes: v })}
              placeholder="Add any notes about this pet..."
              multiline
              numberOfLines={3}
            />
          </Card>

          {/* Delete Button */}
          <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
            <Ionicons name="trash-outline" size={20} color={colors.status.error} />
            <Text style={styles.deleteButtonText}>Remove Pet</Text>
          </TouchableOpacity>
        </ScrollView>

        {/* Footer */}
        <View style={styles.footer}>
          <Button
            title="Cancel"
            variant="outline"
            onPress={() => router.back()}
            style={styles.cancelButton}
          />
          <Button
            title="Save Changes"
            onPress={handleSave}
            loading={isSaving}
            disabled={isSaving}
            style={styles.saveButton}
          />
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    padding: spacing[4],
  },
  photoSection: {
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  card: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  cardTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  cardSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginBottom: spacing[4],
  },
  row: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  halfInput: {
    flex: 1,
  },
  typeSelector: {
    marginBottom: spacing[3],
  },
  typeLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginBottom: spacing[2],
  },
  typeChip: {
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
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
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    marginTop: spacing[4],
  },
  dateContent: {
    flex: 1,
  },
  dateLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  dateValue: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    marginTop: 2,
  },
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[4],
    gap: spacing[2],
    marginTop: spacing[2],
  },
  deleteButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.error,
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
