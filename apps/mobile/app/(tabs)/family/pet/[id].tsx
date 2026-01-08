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

interface PetDetail {
  id: string;
  name: string;
  type: string;
  breed?: string | null;
  color?: string | null;
  age?: number | null;
  weight?: number | null;
  birthDate?: string | null;
  microchipId?: string | null;
  vetName?: string | null;
  vetPhone?: string | null;
  lastVetVisit?: string | null;
  nextVetVisit?: string | null;
  medications?: string | null;
  allergies?: string | null;
  notes?: string | null;
}

const PET_ICONS: Record<string, string> = {
  dog: 'paw',
  cat: 'paw',
  bird: 'leaf',
  fish: 'water',
  rabbit: 'paw',
  hamster: 'paw',
  default: 'paw',
};

export default function PetDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [pet, setPet] = useState<PetDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

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

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Pet',
          headerRight: () => (
            <TouchableOpacity onPress={() => Alert.alert('Edit', 'Edit pet coming soon')}>
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
        {/* Pet Header */}
        <Card style={styles.headerCard}>
          <View style={styles.petIcon}>
            <Ionicons name={petIcon as any} size={48} color={colors.haven.champagne[500]} />
          </View>
          <Text style={styles.petName}>{pet.name}</Text>
          <View style={styles.badgeRow}>
            <Badge label={pet.type} variant="default" />
            {pet.breed && <Badge label={pet.breed} variant="info" />}
          </View>
        </Card>

        {/* Basic Info */}
        <Card style={styles.section}>
          <Text style={styles.sectionTitle}>Basic Info</Text>

          {pet.age !== undefined && pet.age !== null && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Age</Text>
              <Text style={styles.detailValue}>{pet.age} years</Text>
            </View>
          )}

          {pet.color && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Color</Text>
              <Text style={styles.detailValue}>{pet.color}</Text>
            </View>
          )}

          {pet.weight && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Weight</Text>
              <Text style={styles.detailValue}>{pet.weight} lbs</Text>
            </View>
          )}

          {pet.birthDate && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Birthday</Text>
              <Text style={styles.detailValue}>{formatDate(pet.birthDate)}</Text>
            </View>
          )}

          {pet.microchipId && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Microchip ID</Text>
              <Text style={styles.detailValueMono}>{pet.microchipId}</Text>
            </View>
          )}
        </Card>

        {/* Vet Info */}
        {(pet.vetName || pet.vetPhone || pet.lastVetVisit || pet.nextVetVisit) && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Veterinarian</Text>

            {pet.vetName && (
              <View style={styles.detailRow}>
                <Ionicons name="medical-outline" size={18} color={colors.text.tertiary} />
                <View style={styles.detailContent}>
                  <Text style={styles.detailLabel}>Vet</Text>
                  <Text style={styles.detailValue}>{pet.vetName}</Text>
                </View>
                {pet.vetPhone && (
                  <TouchableOpacity onPress={handleCallVet} style={styles.callButton}>
                    <Ionicons name="call" size={20} color={colors.haven.champagne[500]} />
                  </TouchableOpacity>
                )}
              </View>
            )}

            {pet.lastVetVisit && (
              <View style={styles.detailRow}>
                <Ionicons name="calendar-outline" size={18} color={colors.text.tertiary} />
                <View style={styles.detailContent}>
                  <Text style={styles.detailLabel}>Last Visit</Text>
                  <Text style={styles.detailValue}>{formatDate(pet.lastVetVisit)}</Text>
                </View>
              </View>
            )}

            {pet.nextVetVisit && (
              <View style={styles.detailRow}>
                <Ionicons name="calendar" size={18} color={colors.text.tertiary} />
                <View style={styles.detailContent}>
                  <Text style={styles.detailLabel}>Next Visit</Text>
                  <Text style={styles.detailValue}>{formatDate(pet.nextVetVisit)}</Text>
                </View>
                {isUpcomingVetVisit(pet.nextVetVisit) && (
                  <Badge label="Coming Up" variant="warning" />
                )}
              </View>
            )}
          </Card>
        )}

        {/* Health Info */}
        {(pet.medications || pet.allergies) && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Health Information</Text>

            {pet.medications && (
              <View style={styles.healthItem}>
                <View style={styles.healthIcon}>
                  <Ionicons name="medkit" size={20} color={colors.haven.champagne[500]} />
                </View>
                <View style={styles.healthContent}>
                  <Text style={styles.healthLabel}>Medications</Text>
                  <Text style={styles.healthValue}>{pet.medications}</Text>
                </View>
              </View>
            )}

            {pet.allergies && (
              <View style={styles.healthItem}>
                <View style={[styles.healthIcon, { backgroundColor: colors.status.errorLight }]}>
                  <Ionicons name="warning" size={20} color={colors.status.error} />
                </View>
                <View style={styles.healthContent}>
                  <Text style={styles.healthLabel}>Allergies</Text>
                  <Text style={[styles.healthValue, { color: colors.status.error }]}>
                    {pet.allergies}
                  </Text>
                </View>
              </View>
            )}
          </Card>
        )}

        {/* Notes */}
        {pet.notes && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Notes</Text>
            <Text style={styles.notes}>{pet.notes}</Text>
          </Card>
        )}

        {/* Delete Button */}
        <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
          <Ionicons name="trash-outline" size={20} color={colors.status.error} />
          <Text style={styles.deleteButtonText}>Remove Pet</Text>
        </TouchableOpacity>
      </ScrollView>
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
  headerCard: {
    alignItems: 'center',
    padding: spacing[6],
    marginBottom: spacing[4],
  },
  petIcon: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
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
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[3],
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
    gap: spacing[3],
  },
  detailContent: {
    flex: 1,
  },
  detailLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  detailValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    textAlign: 'right',
  },
  detailValueMono: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    fontFamily: 'monospace',
  },
  callButton: {
    padding: spacing[2],
  },
  healthItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  healthIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  healthContent: {
    flex: 1,
  },
  healthLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  healthValue: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  notes: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 22,
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
});
