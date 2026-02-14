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
import { uploadProfileImage } from '../../../../../src/lib/image-upload';

interface Pet {
  id: string;
  name: string;
  type: string;
  breed?: string;
  color?: string;
  birthday?: string;
  weight?: number;
  microchipId?: string;
  notes?: string;
  photoUrls?: string[];
  // Care fields
  foodBrand?: string;
  foodType?: string;
  feedingSchedule?: string;
  dietaryNotes?: string;
  // Vet fields
  primaryVetName?: string;
  vetClinicPhone?: string;
  vetClinicName?: string;
  // Medical
  allergies?: string[];
  medications?: string[];
}

const PET_TYPES = [
  { value: 'DOG', label: 'Dog' },
  { value: 'CAT', label: 'Cat' },
  { value: 'BIRD', label: 'Bird' },
  { value: 'FISH', label: 'Fish' },
  { value: 'RABBIT', label: 'Rabbit' },
  { value: 'HAMSTER', label: 'Hamster' },
  { value: 'REPTILE', label: 'Reptile' },
  { value: 'OTHER', label: 'Other' },
];

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
    type: 'DOG',
    breed: '',
    color: '',
    birthday: null as Date | null,
    weight: '',
    microchipId: '',
    notes: '',
    // Care fields
    foodBrand: '',
    foodType: '',
    feedingSchedule: '',
    dietaryNotes: '',
    // Vet fields
    primaryVetName: '',
    vetClinicPhone: '',
    vetClinicName: '',
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

      const response = await fetch(`${API_BASE_URL}/family/pets/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const pet: Pet = await response.json();
        setFormData({
          name: pet.name || '',
          type: pet.type || 'DOG',
          breed: pet.breed || '',
          color: pet.color || '',
          birthday: pet.birthday ? new Date(pet.birthday) : null,
          weight: pet.weight?.toString() || '',
          microchipId: pet.microchipId || '',
          notes: pet.notes || '',
          foodBrand: pet.foodBrand || '',
          foodType: pet.foodType || '',
          feedingSchedule: pet.feedingSchedule || '',
          dietaryNotes: pet.dietaryNotes || '',
          primaryVetName: pet.primaryVetName || '',
          vetClinicPhone: pet.vetClinicPhone || '',
          vetClinicName: pet.vetClinicName || '',
          allergies: Array.isArray(pet.allergies) ? pet.allergies.join(', ') : '',
          medications: Array.isArray(pet.medications) ? pet.medications.join(', ') : '',
        });
        setPetImage(pet.photoUrls?.[0] || null);
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

      // Upload photo if user picked a new local image
      if (petImage && petImage.startsWith('file://') && id) {
        try {
          const uploadedUrl = await uploadProfileImage('pet', id, petImage);
          setPetImage(uploadedUrl);
        } catch (uploadErr) {
          console.error('Pet photo upload error:', uploadErr);
        }
      }

      // Parse comma-separated strings into arrays
      const allergiesArr = formData.allergies.trim()
        ? formData.allergies.split(',').map((s) => s.trim()).filter(Boolean)
        : [];
      const medicationsArr = formData.medications.trim()
        ? formData.medications.split(',').map((s) => s.trim()).filter(Boolean)
        : [];

      const body = {
        name: formData.name.trim(),
        type: formData.type,
        breed: formData.breed.trim() || null,
        color: formData.color.trim() || null,
        birthday: formData.birthday?.toISOString() || null,
        weight: formData.weight ? parseFloat(formData.weight) : null,
        microchipId: formData.microchipId.trim() || null,
        notes: formData.notes.trim() || null,
        foodBrand: formData.foodBrand.trim() || null,
        foodType: formData.foodType.trim() || null,
        feedingSchedule: formData.feedingSchedule.trim() || null,
        dietaryNotes: formData.dietaryNotes.trim() || null,
        primaryVetName: formData.primaryVetName.trim() || null,
        vetClinicPhone: formData.vetClinicPhone.trim() || null,
        vetClinicName: formData.vetClinicName.trim() || null,
        allergies: allergiesArr,
        medications: medicationsArr,
      };

      const response = await fetch(`${API_BASE_URL}/family/pets/${id}`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
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

              await fetch(`${API_BASE_URL}/family/pets/${id}`, {
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
                {PET_TYPES.map((pt) => (
                  <TouchableOpacity
                    key={pt.value}
                    style={[styles.typeChip, formData.type === pt.value && styles.typeChipActive]}
                    onPress={() => setFormData({ ...formData, type: pt.value })}
                  >
                    <Text style={[styles.typeChipText, formData.type === pt.value && styles.typeChipTextActive]}>
                      {pt.label}
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
                      {formData.birthday
                        ? formData.birthday.toLocaleDateString('en-US', {
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
                value={formData.birthday || new Date()}
                mode="date"
                display="spinner"
                maximumDate={new Date()}
                onChange={(_: any, date?: Date) => {
                  setShowBirthdayPicker(Platform.OS === 'ios');
                  if (date) setFormData({ ...formData, birthday: date });
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
              label="Dietary Notes"
              value={formData.dietaryNotes}
              onChangeText={(v) => setFormData({ ...formData, dietaryNotes: v })}
              placeholder="e.g., 2 cups twice daily, grain-free"
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
              value={formData.vetClinicName}
              onChangeText={(v) => setFormData({ ...formData, vetClinicName: v })}
              placeholder="e.g., Happy Paws Animal Hospital"
              autoCapitalize="words"
            />

            <Input
              label="Vet Name"
              value={formData.primaryVetName}
              onChangeText={(v) => setFormData({ ...formData, primaryVetName: v })}
              placeholder="e.g., Dr. Smith"
              autoCapitalize="words"
            />

            <Input
              label="Phone"
              value={formData.vetClinicPhone}
              onChangeText={(v) => setFormData({ ...formData, vetClinicPhone: v })}
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
