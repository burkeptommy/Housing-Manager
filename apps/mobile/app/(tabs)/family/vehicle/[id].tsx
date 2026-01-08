import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

interface VehicleDetail {
  id: string;
  name?: string | null;
  year: number;
  make: string;
  model: string;
  color?: string | null;
  licensePlate?: string | null;
  vin?: string | null;
  registrationExpiry?: string | null;
  insuranceExpiry?: string | null;
  notes?: string | null;
}

export default function VehicleDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [vehicle, setVehicle] = useState<VehicleDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchVehicle = useCallback(async () => {
    if (!id || !householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdInfo.id}/vehicle/${id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch vehicle: ${response.status}`);
      }

      const data: VehicleDetail = await response.json();
      setVehicle(data);
      setError(null);
    } catch (err) {
      console.error('Fetch vehicle error:', err);
      setError('Failed to load vehicle details.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchVehicle();
  }, [fetchVehicle]);

  const handleDelete = async () => {
    Alert.alert(
      'Delete Vehicle',
      'Are you sure you want to delete this vehicle? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired.');
                return;
              }

              const response = await fetch(
                `${API_BASE_URL}/family/household/${householdInfo?.id}/vehicle/${id}`,
                {
                  method: 'DELETE',
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );

              if (!response.ok) throw new Error('Failed to delete');

              Alert.alert('Deleted', 'Vehicle has been deleted.');
              router.back();
            } catch (err) {
              Alert.alert('Error', 'Failed to delete vehicle.');
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

  const isExpiringSoon = (dateString?: string | null) => {
    if (!dateString) return false;
    const daysUntil = Math.ceil(
      (new Date(dateString).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );
    return daysUntil <= 30 && daysUntil > 0;
  };

  const isExpired = (dateString?: string | null) => {
    if (!dateString) return false;
    return new Date(dateString) < new Date();
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading vehicle..." />;
  }

  if (error || !vehicle) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Vehicle' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Vehicle</Text>
          <Text style={styles.errorText}>{error || 'Vehicle not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchVehicle}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const vehicleName = `${vehicle.year} ${vehicle.make} ${vehicle.model}`;

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Vehicle',
          headerRight: () => (
            <TouchableOpacity onPress={() => Alert.alert('Edit', 'Edit vehicle coming soon')}>
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
              fetchVehicle();
            }}
          />
        }
      >
        {/* Vehicle Header */}
        <Card style={styles.headerCard}>
          <View style={styles.vehicleIcon}>
            <Ionicons name="car" size={48} color={colors.haven.navy[600]} />
          </View>
          <Text style={styles.vehicleName}>{vehicleName}</Text>
          {vehicle.name && (
            <Text style={styles.nickname}>"{vehicle.name}"</Text>
          )}
          {vehicle.color && (
            <Badge label={vehicle.color} variant="default" />
          )}
        </Card>

        {/* Vehicle Details */}
        <Card style={styles.section}>
          <Text style={styles.sectionTitle}>Details</Text>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Year</Text>
            <Text style={styles.detailValue}>{vehicle.year}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Make</Text>
            <Text style={styles.detailValue}>{vehicle.make}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Model</Text>
            <Text style={styles.detailValue}>{vehicle.model}</Text>
          </View>

          {vehicle.color && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Color</Text>
              <Text style={styles.detailValue}>{vehicle.color}</Text>
            </View>
          )}

          {vehicle.licensePlate && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>License Plate</Text>
              <Text style={styles.detailValueMono}>{vehicle.licensePlate}</Text>
            </View>
          )}

          {vehicle.vin && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>VIN</Text>
              <Text style={styles.detailValueMono}>{vehicle.vin}</Text>
            </View>
          )}
        </Card>

        {/* Registration & Insurance */}
        {(vehicle.registrationExpiry || vehicle.insuranceExpiry) && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Registration & Insurance</Text>

            {vehicle.registrationExpiry && (
              <View style={styles.expiryRow}>
                <View style={styles.expiryInfo}>
                  <Ionicons name="document-text-outline" size={20} color={colors.text.tertiary} />
                  <View style={styles.expiryContent}>
                    <Text style={styles.expiryLabel}>Registration</Text>
                    <Text
                      style={[
                        styles.expiryDate,
                        isExpired(vehicle.registrationExpiry) && styles.expiredText,
                      ]}
                    >
                      {formatDate(vehicle.registrationExpiry)}
                    </Text>
                  </View>
                </View>
                {isExpired(vehicle.registrationExpiry) ? (
                  <Badge label="Expired" variant="error" />
                ) : isExpiringSoon(vehicle.registrationExpiry) ? (
                  <Badge label="Expiring Soon" variant="warning" />
                ) : (
                  <Badge label="Valid" variant="success" />
                )}
              </View>
            )}

            {vehicle.insuranceExpiry && (
              <View style={styles.expiryRow}>
                <View style={styles.expiryInfo}>
                  <Ionicons name="shield-checkmark-outline" size={20} color={colors.text.tertiary} />
                  <View style={styles.expiryContent}>
                    <Text style={styles.expiryLabel}>Insurance</Text>
                    <Text
                      style={[
                        styles.expiryDate,
                        isExpired(vehicle.insuranceExpiry) && styles.expiredText,
                      ]}
                    >
                      {formatDate(vehicle.insuranceExpiry)}
                    </Text>
                  </View>
                </View>
                {isExpired(vehicle.insuranceExpiry) ? (
                  <Badge label="Expired" variant="error" />
                ) : isExpiringSoon(vehicle.insuranceExpiry) ? (
                  <Badge label="Expiring Soon" variant="warning" />
                ) : (
                  <Badge label="Valid" variant="success" />
                )}
              </View>
            )}
          </Card>
        )}

        {/* Notes */}
        {vehicle.notes && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Notes</Text>
            <Text style={styles.notes}>{vehicle.notes}</Text>
          </Card>
        )}

        {/* Delete Button */}
        <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
          <Ionicons name="trash-outline" size={20} color={colors.status.error} />
          <Text style={styles.deleteButtonText}>Delete Vehicle</Text>
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
  vehicleIcon: {
    width: 96,
    height: 96,
    borderRadius: borderRadius.xl,
    backgroundColor: colors.haven.navy[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
  },
  vehicleName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    textAlign: 'center',
    marginBottom: spacing[1],
  },
  nickname: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    fontStyle: 'italic',
    marginBottom: spacing[2],
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
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  detailLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  detailValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  detailValueMono: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    fontFamily: 'monospace',
  },
  expiryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  expiryInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
  },
  expiryContent: {
    flex: 1,
  },
  expiryLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  expiryDate: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  expiredText: {
    color: colors.status.error,
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
