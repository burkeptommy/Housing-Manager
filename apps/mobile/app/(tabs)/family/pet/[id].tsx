import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
  Linking,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';
import { EditPetBasicInfoModal } from '../../../../src/components/forms/EditPetBasicInfoModal';
import { EditPetVetModal } from '../../../../src/components/forms/EditPetVetModal';
import { EditPetCareModal } from '../../../../src/components/forms/EditPetCareModal';
import { AddVaccinationModal } from '../../../../src/components/forms/AddVaccinationModal';
import { AddMedicationModal } from '../../../../src/components/forms/AddMedicationModal';
import { EditPetIdModal } from '../../../../src/components/forms/EditPetIdModal';

// =============================================================================
// TYPES
// =============================================================================

interface VetInfo {
  clinicName?: string | null;
  vetName?: string | null;
  phone?: string | null;
  address?: string | null;
  lastVisit?: string | null;
  nextVisit?: string | null;
}

interface Vaccination {
  id: string;
  name: string;
  date: string;
  expiresAt?: string | null;
  notes?: string | null;
}

interface Medication {
  id: string;
  name: string;
  dosage: string;
  frequency: string;
  prescribedBy?: string | null;
}

interface CareInfo {
  foodBrand?: string | null;
  foodType?: string | null;
  feedingSchedule?: string | null;
  monthlyFoodCost?: number | null;
  groomer?: string | null;
  groomerPhone?: string | null;
  groomingFrequency?: string | null;
  walker?: string | null;
  walkerPhone?: string | null;
  boardingFacility?: string | null;
}

interface Registration {
  microchipId?: string | null;
  licenseNumber?: string | null;
  licenseExpires?: string | null;
}

interface PetInsurance {
  provider?: string | null;
  policyNumber?: string | null;
  monthlyPremium?: number | null;
}

interface PetDetail {
  id: string;
  name: string;
  type: string;
  breed?: string | null;
  color?: string | null;
  age?: number | null;
  weight?: number | null;
  birthDate?: string | null;
  adoptionDate?: string | null;
  microchipId?: string | null;
  vetName?: string | null;
  vetPhone?: string | null;
  lastVetVisit?: string | null;
  nextVetVisit?: string | null;
  medications?: string | null;
  allergies?: string | null;
  notes?: string | null;
  // Enhanced fields
  vet?: VetInfo;
  vaccinations?: Vaccination[];
  medicationList?: Medication[];
  care?: CareInfo;
  registration?: Registration;
  insurance?: PetInsurance;
}

const PET_ICONS: Record<string, keyof typeof Ionicons.glyphMap> = {
  dog: 'paw',
  cat: 'paw',
  bird: 'leaf',
  fish: 'water',
  rabbit: 'paw',
  hamster: 'paw',
  reptile: 'bug-outline',
  default: 'paw',
};

// =============================================================================
// HELPER COMPONENTS
// =============================================================================

interface SectionHeaderProps {
  title: string;
  action?: string;
  onAction?: () => void;
}

function SectionHeader({ title, action, onAction }: SectionHeaderProps) {
  return (
    <View style={helperStyles.sectionHeader}>
      <Text style={helperStyles.sectionHeaderText}>{title}</Text>
      {action && onAction && (
        <TouchableOpacity onPress={onAction}>
          <Text style={helperStyles.sectionAction}>{action}</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

interface InfoRowProps {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  value?: string | null;
  alert?: boolean;
  onPress?: () => void;
}

function InfoRow({ icon, label, value, alert, onPress }: InfoRowProps) {
  if (!value) return null;
  const content = (
    <View style={helperStyles.infoRow}>
      <Ionicons name={icon} size={18} color={colors.text.tertiary} />
      <View style={helperStyles.infoContent}>
        <Text style={helperStyles.infoLabel}>{label}</Text>
        <Text style={[
          helperStyles.infoValue,
          alert && helperStyles.alertText,
          onPress && helperStyles.linkText,
        ]}>
          {value}
        </Text>
      </View>
    </View>
  );
  if (onPress) {
    return <TouchableOpacity onPress={onPress}>{content}</TouchableOpacity>;
  }
  return content;
}

interface EmptyPromptProps {
  text: string;
  onPress?: () => void;
}

function EmptyPrompt({ text, onPress }: EmptyPromptProps) {
  return (
    <TouchableOpacity style={helperStyles.emptyPrompt} onPress={onPress} disabled={!onPress}>
      <Ionicons name="add-circle-outline" size={20} color={colors.haven.champagne[500]} />
      <Text style={helperStyles.emptyPromptText}>{text}</Text>
    </TouchableOpacity>
  );
}

const helperStyles = StyleSheet.create({
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionHeaderText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  sectionAction: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[500],
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[3],
    paddingVertical: spacing[2],
  },
  infoContent: {
    flex: 1,
  },
  infoLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  infoValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  alertText: {
    color: colors.status.error,
  },
  linkText: {
    color: colors.haven.champagne[500],
  },
  emptyPrompt: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
  },
  emptyPromptText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[500],
  },
});

export default function PetDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [pet, setPet] = useState<PetDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Modal states
  const [showBasicInfoModal, setShowBasicInfoModal] = useState(false);
  const [showVetModal, setShowVetModal] = useState(false);
  const [showCareModal, setShowCareModal] = useState(false);
  const [showVaccinationModal, setShowVaccinationModal] = useState(false);
  const [showMedicationModal, setShowMedicationModal] = useState(false);
  const [showIdModal, setShowIdModal] = useState(false);

  const fetchPet = useCallback(async () => {
    if (!id || !householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdInfo.id}/pet/${id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch pet: ${response.status}`);
      }

      const data: PetDetail = await response.json();
      setPet(data);
      setError(null);
    } catch (err) {
      console.error('Fetch pet error:', err);
      setError('Failed to load pet details.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchPet();
  }, [fetchPet]);

  const handleCallVet = () => {
    if (pet?.vetPhone) {
      Linking.openURL(`tel:${pet.vetPhone}`);
    }
  };

  const handleDelete = async () => {
    Alert.alert(
      'Remove Pet',
      'Are you sure you want to remove this pet? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired.');
                return;
              }

              const response = await fetch(
                `${API_BASE_URL}/family/household/${householdInfo?.id}/pet/${id}`,
                {
                  method: 'DELETE',
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );

              if (!response.ok) throw new Error('Failed to delete');

              Alert.alert('Removed', 'Pet has been removed.');
              router.back();
            } catch (err) {
              Alert.alert('Error', 'Failed to remove pet.');
            }
          },
        },
      ]
    );
  };

  // Save basic info
  const handleSaveBasicInfo = async (data: {
    birthDate?: string | null;
    color?: string | null;
    weight?: number | null;
    allergies?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/pet/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchPet();
  };

  // Save vet info
  const handleSaveVetInfo = async (data: {
    vetName?: string | null;
    vetClinic?: string | null;
    vetPhone?: string | null;
    vetAddress?: string | null;
    lastVetVisit?: string | null;
    nextVetVisit?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/pet/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchPet();
  };

  // Save care info (food & feeding)
  const handleSaveCareInfo = async (data: {
    foodBrand?: string | null;
    foodType?: string | null;
    feedingSchedule?: string | null;
    feedingAmount?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/pet/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchPet();
  };

  // Save ID info (microchip, license)
  const handleSaveIdInfo = async (data: {
    microchipId?: string | null;
    licenseNumber?: string | null;
    licenseExpires?: string | null;
    registryName?: string | null;
    registryPhone?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/pet/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          microchipId: data.microchipId,
          licenseNum: data.licenseNumber,
          licenseExpires: data.licenseExpires,
        }),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchPet();
  };

  const formatDate = (dateString?: string | null) => {
    if (!dateString) return null;
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const isUpcomingVetVisit = (dateString?: string | null) => {
    if (!dateString) return false;
    const daysUntil = Math.ceil(
      (new Date(dateString).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );
    return daysUntil <= 14 && daysUntil > 0;
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading pet..." />;
  }

  if (error || !pet) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Pet' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Pet</Text>
          <Text style={styles.errorText}>{error || 'Pet not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchPet}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const petIcon = PET_ICONS[pet.type.toLowerCase()] || PET_ICONS.default;

  // Format currency
  const formatCurrency = (amount?: number | null) => {
    if (!amount) return null;
    return `$${amount.toLocaleString()}`;
  };

  // Check if vaccination is expiring
  const isVaccinationExpiring = (expiresAt?: string | null) => {
    if (!expiresAt) return false;
    const daysUntil = Math.ceil(
      (new Date(expiresAt).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );
    return daysUntil <= 30 && daysUntil > 0;
  };

  const isVaccinationExpired = (expiresAt?: string | null) => {
    if (!expiresAt) return false;
    return new Date(expiresAt) < new Date();
  };

  // Check for vet info
  const hasVetInfo = pet.vet?.clinicName || pet.vet?.vetName || pet.vetName || pet.vetPhone;

  // Check for care info
  const hasCareInfo = pet.care?.foodBrand || pet.care?.feedingSchedule || pet.care?.groomer || pet.care?.walker;

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Pet',
          headerRight: () => (
            <TouchableOpacity onPress={() => router.push(`/(tabs)/family/pet/edit/${id}` as any)}>
              <Ionicons name="create-outline" size={24} color={colors.haven.champagne[500]} />
            </TouchableOpacity>
          ),
        }}
      />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchPet();
            }}
          />
        }
      >
        {/* Hero Card */}
        <Card style={styles.heroCard}>
          <View style={styles.petIconContainer}>
            <Ionicons name={petIcon} size={56} color={colors.haven.champagne[500]} />
          </View>
          <Text style={styles.petName}>{pet.name}</Text>
          <View style={styles.badgeRow}>
            <Badge label={pet.type} variant="default" />
            {pet.breed && <Badge label={pet.breed} variant="info" />}
          </View>
          {pet.age !== undefined && pet.age !== null && (
            <Text style={styles.petAge}>{pet.age} years old</Text>
          )}
        </Card>

        {/* Allergies Alert - Prominent if exists */}
        {pet.allergies && (
          <Card style={styles.allergyCard}>
            <View style={styles.allergyHeader}>
              <Ionicons name="warning" size={20} color={colors.status.error} />
              <Text style={styles.allergyTitle}>ALLERGIES</Text>
            </View>
            <Text style={styles.allergyText}>{pet.allergies}</Text>
          </Card>
        )}

        {/* Basic Info */}
        <Card style={styles.section}>
          <SectionHeader
            title="BASIC INFO"
            action="Edit"
            onAction={() => setShowBasicInfoModal(true)}
          />
          <InfoRow icon="calendar-outline" label="Birthday" value={formatDate(pet.birthDate)} />
          {pet.adoptionDate && (
            <InfoRow icon="heart-outline" label="Adoption Date" value={formatDate(pet.adoptionDate)} />
          )}
          <InfoRow icon="color-palette-outline" label="Color" value={pet.color} />
          {pet.weight && (
            <InfoRow icon="scale-outline" label="Weight" value={`${pet.weight} lbs`} />
          )}
        </Card>

        {/* Veterinarian */}
        <Card style={styles.section}>
          <SectionHeader
            title="VETERINARIAN"
            action="Edit"
            onAction={() => setShowVetModal(true)}
          />
          {hasVetInfo ? (
            <>
              <InfoRow
                icon="medical-outline"
                label="Clinic"
                value={pet.vet?.clinicName}
              />
              <InfoRow
                icon="person-outline"
                label="Veterinarian"
                value={pet.vet?.vetName || pet.vetName}
              />
              <InfoRow
                icon="call-outline"
                label="Phone"
                value={pet.vet?.phone || pet.vetPhone}
                onPress={() => {
                  const phone = pet.vet?.phone || pet.vetPhone;
                  if (phone) Linking.openURL(`tel:${phone}`);
                }}
              />
              <InfoRow
                icon="location-outline"
                label="Address"
                value={pet.vet?.address}
              />
              {(pet.vet?.nextVisit || pet.nextVetVisit) && (
                <View style={styles.appointmentRow}>
                  <View style={styles.appointmentInfo}>
                    <Ionicons name="calendar" size={18} color={colors.haven.navy[600]} />
                    <View style={styles.appointmentContent}>
                      <Text style={styles.appointmentLabel}>Next Appointment</Text>
                      <Text style={styles.appointmentDate}>
                        {formatDate(pet.vet?.nextVisit || pet.nextVetVisit)}
                      </Text>
                    </View>
                  </View>
                  {isUpcomingVetVisit(pet.vet?.nextVisit || pet.nextVetVisit) && (
                    <Badge label="Soon" variant="warning" />
                  )}
                </View>
              )}
              {(pet.vet?.lastVisit || pet.lastVetVisit) && (
                <InfoRow
                  icon="time-outline"
                  label="Last Visit"
                  value={formatDate(pet.vet?.lastVisit || pet.lastVetVisit)}
                />
              )}
            </>
          ) : (
            <EmptyPrompt
              text="Add veterinarian information"
              onPress={() => setShowVetModal(true)}
            />
          )}
        </Card>

        {/* Vaccinations */}
        <Card style={styles.section}>
          <SectionHeader
            title="VACCINATIONS"
            action="+ Add"
            onAction={() => setShowVaccinationModal(true)}
          />
          {pet.vaccinations && pet.vaccinations.length > 0 ? (
            pet.vaccinations.map((vaccination) => (
              <TouchableOpacity key={vaccination.id} style={styles.vaccinationRow}>
                <View style={[
                  styles.vaccinationIcon,
                  isVaccinationExpired(vaccination.expiresAt) && styles.vaccinationIconExpired,
                ]}>
                  <Ionicons
                    name="shield-checkmark-outline"
                    size={18}
                    color={isVaccinationExpired(vaccination.expiresAt)
                      ? colors.status.error
                      : colors.haven.navy[600]}
                  />
                </View>
                <View style={styles.vaccinationContent}>
                  <Text style={styles.vaccinationName}>{vaccination.name}</Text>
                  <Text style={styles.vaccinationDate}>
                    Given: {new Date(vaccination.date).toLocaleDateString()}
                  </Text>
                  {vaccination.expiresAt && (
                    <Text style={[
                      styles.vaccinationExpiry,
                      isVaccinationExpired(vaccination.expiresAt) && styles.expiredText,
                    ]}>
                      Expires: {new Date(vaccination.expiresAt).toLocaleDateString()}
                    </Text>
                  )}
                </View>
                {isVaccinationExpired(vaccination.expiresAt) ? (
                  <Badge label="Expired" variant="error" />
                ) : isVaccinationExpiring(vaccination.expiresAt) ? (
                  <Badge label="Due Soon" variant="warning" />
                ) : vaccination.expiresAt ? (
                  <Badge label="Current" variant="success" />
                ) : null}
              </TouchableOpacity>
            ))
          ) : (
            <EmptyPrompt
              text="Add vaccination records"
              onPress={() => setShowVaccinationModal(true)}
            />
          )}
        </Card>

        {/* Medications */}
        {(pet.medicationList && pet.medicationList.length > 0) || pet.medications ? (
          <Card style={styles.section}>
            <SectionHeader
              title="MEDICATIONS"
              action="+ Add"
              onAction={() => setShowMedicationModal(true)}
            />
            {pet.medicationList && pet.medicationList.length > 0 ? (
              pet.medicationList.map((med) => (
                <View key={med.id} style={styles.medicationRow}>
                  <View style={styles.medicationIcon}>
                    <Ionicons name="medkit-outline" size={18} color={colors.haven.champagne[500]} />
                  </View>
                  <View style={styles.medicationContent}>
                    <Text style={styles.medicationName}>{med.name}</Text>
                    <Text style={styles.medicationDosage}>{med.dosage}</Text>
                    <Text style={styles.medicationFrequency}>{med.frequency}</Text>
                  </View>
                </View>
              ))
            ) : pet.medications ? (
              <View style={styles.medicationRow}>
                <View style={styles.medicationIcon}>
                  <Ionicons name="medkit-outline" size={18} color={colors.haven.champagne[500]} />
                </View>
                <View style={styles.medicationContent}>
                  <Text style={styles.medicationName}>{pet.medications}</Text>
                </View>
              </View>
            ) : null}
          </Card>
        ) : null}

        {/* Care Instructions */}
        <Card style={styles.section}>
          <SectionHeader
            title="CARE"
            action="Edit"
            onAction={() => setShowCareModal(true)}
          />
          {hasCareInfo ? (
            <>
              {(pet.care?.foodBrand || pet.care?.foodType) && (
                <View style={styles.careCard}>
                  <Ionicons name="restaurant-outline" size={20} color={colors.haven.navy[600]} />
                  <View style={styles.careContent}>
                    <Text style={styles.careLabel}>Food</Text>
                    {pet.care?.foodBrand && (
                      <Text style={styles.careValue}>{pet.care.foodBrand}</Text>
                    )}
                    {pet.care?.foodType && (
                      <Text style={styles.careSubvalue}>{pet.care.foodType}</Text>
                    )}
                  </View>
                </View>
              )}
              {pet.care?.feedingSchedule && (
                <InfoRow
                  icon="time-outline"
                  label="Feeding Schedule"
                  value={pet.care.feedingSchedule}
                />
              )}
              {pet.care?.groomer && (
                <View style={styles.serviceProviderCard}>
                  <Ionicons name="cut-outline" size={20} color={colors.text.tertiary} />
                  <View style={styles.serviceProviderContent}>
                    <Text style={styles.serviceProviderLabel}>Groomer</Text>
                    <Text style={styles.serviceProviderName}>{pet.care.groomer}</Text>
                    {pet.care.groomingFrequency && (
                      <Text style={styles.serviceProviderNote}>{pet.care.groomingFrequency}</Text>
                    )}
                  </View>
                  {pet.care.groomerPhone && (
                    <TouchableOpacity
                      style={styles.callButton}
                      onPress={() => Linking.openURL(`tel:${pet.care?.groomerPhone}`)}
                    >
                      <Ionicons name="call-outline" size={20} color={colors.haven.champagne[500]} />
                    </TouchableOpacity>
                  )}
                </View>
              )}
              {pet.care?.walker && (
                <View style={styles.serviceProviderCard}>
                  <Ionicons name="walk-outline" size={20} color={colors.text.tertiary} />
                  <View style={styles.serviceProviderContent}>
                    <Text style={styles.serviceProviderLabel}>Dog Walker</Text>
                    <Text style={styles.serviceProviderName}>{pet.care.walker}</Text>
                  </View>
                  {pet.care.walkerPhone && (
                    <TouchableOpacity
                      style={styles.callButton}
                      onPress={() => Linking.openURL(`tel:${pet.care?.walkerPhone}`)}
                    >
                      <Ionicons name="call-outline" size={20} color={colors.haven.champagne[500]} />
                    </TouchableOpacity>
                  )}
                </View>
              )}
              {pet.care?.boardingFacility && (
                <InfoRow
                  icon="home-outline"
                  label="Boarding Facility"
                  value={pet.care.boardingFacility}
                />
              )}
            </>
          ) : (
            <EmptyPrompt
              text="Add care instructions"
              onPress={() => setShowCareModal(true)}
            />
          )}
        </Card>

        {/* IDs & Registration */}
        <Card style={styles.section}>
          <SectionHeader
            title="IDS & REGISTRATION"
            action="Edit"
            onAction={() => setShowIdModal(true)}
          />
          {pet.microchipId || pet.registration?.microchipId || pet.registration?.licenseNumber ? (
            <>
              <InfoRow
                icon="qr-code-outline"
                label="Microchip ID"
                value={pet.registration?.microchipId || pet.microchipId}
              />
              <InfoRow
                icon="card-outline"
                label="License Number"
                value={pet.registration?.licenseNumber}
              />
              {pet.registration?.licenseExpires && (
                <InfoRow
                  icon="calendar-outline"
                  label="License Expires"
                  value={formatDate(pet.registration.licenseExpires)}
                  alert={isVaccinationExpired(pet.registration.licenseExpires)}
                />
              )}
            </>
          ) : (
            <EmptyPrompt
              text="Add microchip or license info"
              onPress={() => setShowIdModal(true)}
            />
          )}
        </Card>

        {/* Insurance */}
        {pet.insurance?.provider && (
          <Card style={styles.section}>
            <SectionHeader
              title="PET INSURANCE"
              action="Edit"
              onAction={() => router.push(`/(tabs)/family/pet/edit/${id}` as any)}
            />
            <InfoRow
              icon="shield-outline"
              label="Provider"
              value={pet.insurance.provider}
            />
            <InfoRow
              icon="document-outline"
              label="Policy #"
              value={pet.insurance.policyNumber}
            />
            <InfoRow
              icon="cash-outline"
              label="Monthly Premium"
              value={formatCurrency(pet.insurance.monthlyPremium)}
            />
          </Card>
        )}

        {/* Notes */}
        {pet.notes && (
          <Card style={styles.section}>
            <SectionHeader title="NOTES" />
            <Text style={styles.notes}>{pet.notes}</Text>
          </Card>
        )}

        {/* Delete Button */}
        <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
          <Ionicons name="trash-outline" size={20} color={colors.status.error} />
          <Text style={styles.deleteButtonText}>Remove Pet</Text>
        </TouchableOpacity>
      </ScrollView>

      {/* Focused Edit Modals */}
      <EditPetBasicInfoModal
        visible={showBasicInfoModal}
        onClose={() => setShowBasicInfoModal(false)}
        onSave={handleSaveBasicInfo}
        initialData={{
          birthDate: pet.birthDate,
          color: pet.color,
          weight: pet.weight,
          allergies: pet.allergies,
        }}
      />

      <EditPetVetModal
        visible={showVetModal}
        onClose={() => setShowVetModal(false)}
        onSave={handleSaveVetInfo}
        initialData={{
          vetName: pet.vet?.vetName || pet.vetName,
          vetClinic: pet.vet?.clinicName,
          vetPhone: pet.vet?.phone || pet.vetPhone,
          vetAddress: pet.vet?.address,
          lastVetVisit: pet.vet?.lastVisit || pet.lastVetVisit,
          nextVetVisit: pet.vet?.nextVisit || pet.nextVetVisit,
        }}
      />

      <EditPetCareModal
        visible={showCareModal}
        onClose={() => setShowCareModal(false)}
        onSave={handleSaveCareInfo}
        initialData={{
          foodBrand: pet.care?.foodBrand,
          foodType: pet.care?.foodType,
          feedingSchedule: pet.care?.feedingSchedule,
        }}
      />

      <AddVaccinationModal
        visible={showVaccinationModal}
        onClose={() => setShowVaccinationModal(false)}
        petId={id!}
        householdId={householdInfo?.id || ''}
        onSuccess={fetchPet}
      />

      <AddMedicationModal
        visible={showMedicationModal}
        onClose={() => setShowMedicationModal(false)}
        petId={id!}
        householdId={householdInfo?.id || ''}
        onSuccess={fetchPet}
      />

      <EditPetIdModal
        visible={showIdModal}
        onClose={() => setShowIdModal(false)}
        onSave={handleSaveIdInfo}
        initialData={{
          microchipId: pet.registration?.microchipId || pet.microchipId,
          licenseNumber: pet.registration?.licenseNumber,
          licenseExpires: pet.registration?.licenseExpires,
        }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  errorTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
  retryButton: {
    marginTop: spacing[4],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  // Hero Card
  heroCard: {
    alignItems: 'center',
    padding: spacing[6],
    marginBottom: spacing[4],
  },
  petIconContainer: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  petName: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  badgeRow: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  petAge: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: spacing[2],
  },
  // Allergy Alert Card
  allergyCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
    backgroundColor: colors.status.errorLight,
    borderLeftWidth: 4,
    borderLeftColor: colors.status.error,
  },
  allergyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  allergyTitle: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.bold,
    color: colors.status.error,
    letterSpacing: 0.5,
  },
  allergyText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.error,
  },
  // Sections
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  // Appointment row
  appointmentRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.haven.navy[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[2],
  },
  appointmentInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    flex: 1,
  },
  appointmentContent: {
    flex: 1,
  },
  appointmentLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  appointmentDate: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  // Vaccinations
  vaccinationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  vaccinationIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.full,
    backgroundColor: colors.haven.navy[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  vaccinationIconExpired: {
    backgroundColor: colors.status.errorLight,
  },
  vaccinationContent: {
    flex: 1,
  },
  vaccinationName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  vaccinationDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  vaccinationExpiry: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  expiredText: {
    color: colors.status.error,
  },
  // Medications
  medicationRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[3],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  medicationIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.full,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  medicationContent: {
    flex: 1,
  },
  medicationName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  medicationDosage: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  medicationFrequency: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  // Care
  careCard: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[3],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.haven.navy[50],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[2],
  },
  careContent: {
    flex: 1,
  },
  careLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  careValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  careSubvalue: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  // Service Provider Cards (groomer, walker)
  serviceProviderCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  serviceProviderContent: {
    flex: 1,
  },
  serviceProviderLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  serviceProviderName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  serviceProviderNote: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  callButton: {
    padding: spacing[2],
  },
  // Notes
  notes: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 22,
  },
  // Delete Button
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
});
