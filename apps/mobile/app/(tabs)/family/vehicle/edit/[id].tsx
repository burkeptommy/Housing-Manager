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

interface ServiceProvider {
  id?: string;
  name: string;
  phone?: string;
  type: string; // 'mechanic', 'dealer', 'body_shop', 'tire', 'other'
}

interface Vehicle {
  id: string;
  make: string;
  model: string;
  year: number;
  color?: string;
  licensePlate?: string;
  vin?: string;
  insuranceExpiry?: string;
  registrationExpiry?: string;
  registrationDocUrl?: string;
  notes?: string;
  imageUrl?: string;
  serviceProviders?: ServiceProvider[];
}

export default function EditVehicleScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [showInsurancePicker, setShowInsurancePicker] = useState(false);
  const [showRegistrationPicker, setShowRegistrationPicker] = useState(false);
  const [vehicleImage, setVehicleImage] = useState<string | null>(null);
  const [registrationDoc, setRegistrationDoc] = useState<string | null>(null);
  const [serviceProviders, setServiceProviders] = useState<ServiceProvider[]>([]);
  const [showAddProvider, setShowAddProvider] = useState(false);
  const [newProvider, setNewProvider] = useState({ name: '', phone: '', type: 'mechanic' });

  const [formData, setFormData] = useState({
    make: '',
    model: '',
    year: new Date().getFullYear().toString(),
    color: '',
    licensePlate: '',
    vin: '',
    insuranceExpiry: null as Date | null,
    registrationExpiry: null as Date | null,
    notes: '',
  });

  const fetchVehicle = useCallback(async () => {
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

      const response = await fetch(`${API_BASE_URL}/households/${householdInfo.id}/vehicles/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const vehicle: Vehicle = await response.json();
        setFormData({
          make: vehicle.make || '',
          model: vehicle.model || '',
          year: vehicle.year?.toString() || new Date().getFullYear().toString(),
          color: vehicle.color || '',
          licensePlate: vehicle.licensePlate || '',
          vin: vehicle.vin || '',
          insuranceExpiry: vehicle.insuranceExpiry ? new Date(vehicle.insuranceExpiry) : null,
          registrationExpiry: vehicle.registrationExpiry ? new Date(vehicle.registrationExpiry) : null,
          notes: vehicle.notes || '',
        });
        setVehicleImage(vehicle.imageUrl || null);
        setRegistrationDoc(vehicle.registrationDocUrl || null);
        setServiceProviders(vehicle.serviceProviders || []);
      }
    } catch (err) {
      console.error('Fetch vehicle error:', err);
    } finally {
      setIsLoading(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchVehicle();
  }, [fetchVehicle]);

  const handleSave = async () => {
    if (!formData.make.trim()) {
      Alert.alert('Required', 'Make is required');
      return;
    }
    if (!formData.model.trim()) {
      Alert.alert('Required', 'Model is required');
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
        make: formData.make.trim(),
        model: formData.model.trim(),
        year: parseInt(formData.year) || new Date().getFullYear(),
        color: formData.color.trim() || null,
        licensePlate: formData.licensePlate.trim() || null,
        vin: formData.vin.trim() || null,
        insuranceExpiry: formData.insuranceExpiry?.toISOString() || null,
        registrationExpiry: formData.registrationExpiry?.toISOString() || null,
        registrationDocUrl: registrationDoc,
        notes: formData.notes.trim() || null,
        imageUrl: vehicleImage,
        serviceProviders: serviceProviders,
      };

      const response = await fetch(`${API_BASE_URL}/households/${householdInfo?.id}/vehicles/${id}`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (!response.ok && response.status !== 404) {
        throw new Error('Failed to update vehicle');
      }

      Alert.alert('Success', 'Vehicle updated successfully', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (error) {
      console.error('Update vehicle error:', error);
      Alert.alert('Error', 'Failed to update vehicle. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = () => {
    Alert.alert(
      'Remove Vehicle',
      'Are you sure you want to remove this vehicle? This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) return;

              await fetch(`${API_BASE_URL}/households/${householdInfo?.id}/vehicles/${id}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` },
              });

              router.back();
            } catch (err) {
              console.error('Delete vehicle error:', err);
              Alert.alert('Error', 'Failed to remove vehicle');
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
      <Stack.Screen options={{ title: 'Edit Vehicle' }} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Vehicle Photo */}
          <View style={styles.photoSection}>
            <ImageUpload
              currentImage={vehicleImage}
              onImageSelected={setVehicleImage}
              shape="rectangle"
              size="large"
              placeholder="Add Vehicle Photo"
            />
          </View>

          {/* Basic Info */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Vehicle Information</Text>

            <View style={styles.row}>
              <View style={styles.halfInput}>
                <Input
                  label="Make"
                  value={formData.make}
                  onChangeText={(v) => setFormData({ ...formData, make: v })}
                  placeholder="e.g., Toyota"
                  autoCapitalize="words"
                />
              </View>
              <View style={styles.halfInput}>
                <Input
                  label="Model"
                  value={formData.model}
                  onChangeText={(v) => setFormData({ ...formData, model: v })}
                  placeholder="e.g., Camry"
                  autoCapitalize="words"
                />
              </View>
            </View>

            <View style={styles.row}>
              <View style={styles.halfInput}>
                <Input
                  label="Year"
                  value={formData.year}
                  onChangeText={(v) => setFormData({ ...formData, year: v.replace(/[^0-9]/g, '').slice(0, 4) })}
                  keyboardType="number-pad"
                  placeholder="2024"
                  maxLength={4}
                />
              </View>
              <View style={styles.halfInput}>
                <Input
                  label="Color"
                  value={formData.color}
                  onChangeText={(v) => setFormData({ ...formData, color: v })}
                  placeholder="e.g., Silver"
                  autoCapitalize="words"
                />
              </View>
            </View>

            <Input
              label="License Plate"
              value={formData.licensePlate}
              onChangeText={(v) => setFormData({ ...formData, licensePlate: v.toUpperCase() })}
              placeholder="e.g., ABC 1234"
              autoCapitalize="characters"
            />

            <Input
              label="VIN"
              value={formData.vin}
              onChangeText={(v) => setFormData({ ...formData, vin: v.toUpperCase() })}
              placeholder="Vehicle Identification Number"
              autoCapitalize="characters"
              maxLength={17}
            />
          </Card>

          {/* Expiration Dates */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Important Dates</Text>

            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowInsurancePicker(true)}
            >
              <Ionicons name="shield-checkmark-outline" size={20} color={colors.haven.champagne[500]} />
              <View style={styles.dateContent}>
                <Text style={styles.dateLabel}>Insurance Expiry</Text>
                <Text style={styles.dateValue}>
                  {formData.insuranceExpiry
                    ? formData.insuranceExpiry.toLocaleDateString('en-US', {
                        month: 'long',
                        day: 'numeric',
                        year: 'numeric',
                      })
                    : 'Not set'}
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>

            {showInsurancePicker && (
              <DateTimePicker
                value={formData.insuranceExpiry || new Date()}
                mode="date"
                display="spinner"
                onChange={(_: any, date?: Date) => {
                  setShowInsurancePicker(Platform.OS === 'ios');
                  if (date) setFormData({ ...formData, insuranceExpiry: date });
                }}
              />
            )}

            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowRegistrationPicker(true)}
            >
              <Ionicons name="document-text-outline" size={20} color={colors.haven.champagne[500]} />
              <View style={styles.dateContent}>
                <Text style={styles.dateLabel}>Registration Expiry</Text>
                <Text style={styles.dateValue}>
                  {formData.registrationExpiry
                    ? formData.registrationExpiry.toLocaleDateString('en-US', {
                        month: 'long',
                        day: 'numeric',
                        year: 'numeric',
                      })
                    : 'Not set'}
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>

            {showRegistrationPicker && (
              <DateTimePicker
                value={formData.registrationExpiry || new Date()}
                mode="date"
                display="spinner"
                onChange={(_: any, date?: Date) => {
                  setShowRegistrationPicker(Platform.OS === 'ios');
                  if (date) setFormData({ ...formData, registrationExpiry: date });
                }}
              />
            )}
          </Card>

          {/* Registration Document */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Registration Document</Text>
            <Text style={styles.cardSubtitle}>Upload a photo of your registration for safekeeping</Text>
            <ImageUpload
              currentImage={registrationDoc}
              onImageSelected={setRegistrationDoc}
              shape="rectangle"
              size="medium"
              placeholder="Upload Registration"
            />
          </Card>

          {/* Service Providers */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Service Providers</Text>
            <Text style={styles.cardSubtitle}>Add mechanics, dealers, and other service shops</Text>

            {serviceProviders.map((provider, index) => (
              <View key={index} style={styles.providerRow}>
                <View style={styles.providerIcon}>
                  <Ionicons
                    name={provider.type === 'dealer' ? 'car-sport-outline' :
                          provider.type === 'tire' ? 'ellipse-outline' :
                          provider.type === 'body_shop' ? 'color-palette-outline' :
                          'build-outline'}
                    size={20}
                    color={colors.haven.champagne[500]}
                  />
                </View>
                <View style={styles.providerInfo}>
                  <Text style={styles.providerName}>{provider.name}</Text>
                  <Text style={styles.providerType}>
                    {provider.type === 'mechanic' ? 'Mechanic' :
                     provider.type === 'dealer' ? 'Dealer' :
                     provider.type === 'body_shop' ? 'Body Shop' :
                     provider.type === 'tire' ? 'Tire Shop' : 'Other'}
                  </Text>
                  {provider.phone && <Text style={styles.providerPhone}>{provider.phone}</Text>}
                </View>
                <TouchableOpacity
                  onPress={() => {
                    const updated = [...serviceProviders];
                    updated.splice(index, 1);
                    setServiceProviders(updated);
                  }}
                  style={styles.removeButton}
                >
                  <Ionicons name="close-circle" size={24} color={colors.status.error} />
                </TouchableOpacity>
              </View>
            ))}

            {showAddProvider ? (
              <View style={styles.addProviderForm}>
                <Input
                  label="Business Name"
                  value={newProvider.name}
                  onChangeText={(v) => setNewProvider({ ...newProvider, name: v })}
                  placeholder="e.g., Joe's Auto Shop"
                />
                <Input
                  label="Phone (optional)"
                  value={newProvider.phone}
                  onChangeText={(v) => setNewProvider({ ...newProvider, phone: v })}
                  placeholder="(555) 123-4567"
                  keyboardType="phone-pad"
                />
                <View style={styles.typeSelector}>
                  <Text style={styles.typeLabel}>Type</Text>
                  <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                    {['mechanic', 'dealer', 'body_shop', 'tire', 'other'].map((type) => (
                      <TouchableOpacity
                        key={type}
                        style={[styles.typeChip, newProvider.type === type && styles.typeChipActive]}
                        onPress={() => setNewProvider({ ...newProvider, type })}
                      >
                        <Text style={[styles.typeChipText, newProvider.type === type && styles.typeChipTextActive]}>
                          {type === 'mechanic' ? 'Mechanic' :
                           type === 'dealer' ? 'Dealer' :
                           type === 'body_shop' ? 'Body Shop' :
                           type === 'tire' ? 'Tire Shop' : 'Other'}
                        </Text>
                      </TouchableOpacity>
                    ))}
                  </ScrollView>
                </View>
                <View style={styles.addProviderActions}>
                  <TouchableOpacity
                    style={styles.cancelAddButton}
                    onPress={() => {
                      setShowAddProvider(false);
                      setNewProvider({ name: '', phone: '', type: 'mechanic' });
                    }}
                  >
                    <Text style={styles.cancelAddText}>Cancel</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.confirmAddButton}
                    onPress={() => {
                      if (newProvider.name.trim()) {
                        setServiceProviders([...serviceProviders, {
                          name: newProvider.name.trim(),
                          phone: newProvider.phone.trim() || undefined,
                          type: newProvider.type,
                        }]);
                        setNewProvider({ name: '', phone: '', type: 'mechanic' });
                        setShowAddProvider(false);
                      } else {
                        Alert.alert('Required', 'Please enter a business name');
                      }
                    }}
                  >
                    <Text style={styles.confirmAddText}>Add Provider</Text>
                  </TouchableOpacity>
                </View>
              </View>
            ) : (
              <TouchableOpacity
                style={styles.addProviderButton}
                onPress={() => setShowAddProvider(true)}
              >
                <Ionicons name="add-circle-outline" size={24} color={colors.haven.champagne[500]} />
                <Text style={styles.addProviderText}>Add Service Provider</Text>
              </TouchableOpacity>
            )}
          </Card>

          {/* Notes */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Notes</Text>
            <Input
              value={formData.notes}
              onChangeText={(v) => setFormData({ ...formData, notes: v })}
              placeholder="Add any notes about this vehicle..."
              multiline
              numberOfLines={3}
            />
          </Card>

          {/* Delete Button */}
          <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
            <Ionicons name="trash-outline" size={20} color={colors.status.error} />
            <Text style={styles.deleteButtonText}>Remove Vehicle</Text>
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
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    marginBottom: spacing[3],
  },
  dateContent: {
    flex: 1,
    marginLeft: spacing[3],
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
  // Service Providers
  providerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  providerIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  providerInfo: {
    flex: 1,
  },
  providerName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  providerType: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    marginTop: 2,
  },
  providerPhone: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  removeButton: {
    padding: spacing[2],
  },
  addProviderButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[4],
    gap: spacing[2],
    borderWidth: 1,
    borderColor: colors.haven.champagne[300],
    borderStyle: 'dashed',
    borderRadius: borderRadius.lg,
    marginTop: spacing[2],
  },
  addProviderText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.champagne[500],
    fontWeight: typography.fontWeights.medium,
  },
  addProviderForm: {
    padding: spacing[4],
    backgroundColor: colors.gray[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[2],
  },
  typeSelector: {
    marginTop: spacing[2],
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
  addProviderActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing[3],
    marginTop: spacing[2],
  },
  cancelAddButton: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
  },
  cancelAddText: {
    fontSize: typography.fontSizes.base,
    color: colors.text.tertiary,
  },
  confirmAddButton: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
  },
  confirmAddText: {
    fontSize: typography.fontSizes.base,
    color: colors.white,
    fontWeight: typography.fontWeights.medium,
  },
});
