import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Image,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { colors, spacing, typography, borderRadius } from '../../src/lib/theme';
import { getIdToken } from '../../src/lib/firebase';
import { API_BASE_URL } from '../../src/lib/api';

interface PropertyDetails {
  bedrooms: number | null;
  bathrooms: number | null;
  squareFeet: number | null;
  yearBuilt: number | null;
  lotSizeAcres: number | null;
  stories: number | null;
  heatingType: string | null;
  heatingFuel: string | null;
  coolingType: string | null;
  waterType: string | null;
  sewerType: string | null;
  garageSpaces: number | null;
  pool: boolean | null;
  propertyType: string | null;
}

export default function ConfirmPropertyScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();
  const { completeSocialRegistration, pendingSocialAuth } = useAuth();

  const street = params.street as string;
  const city = params.city as string;
  const state = params.state as string;
  const zipCode = params.zipCode as string;
  const formatted = params.formatted as string;
  const firstName = params.firstName as string;
  const lastName = params.lastName as string;
  const email = params.email as string;

  const [propertyDetails, setPropertyDetails] = useState<PropertyDetails | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Fetch property details via API
  useEffect(() => {
    fetchPropertyDetails();
  }, []);

  const fetchPropertyDetails = async () => {
    setIsLoading(true);
    try {
      const token = await getIdToken();

      const queryParams = new URLSearchParams({
        street,
        city,
        state,
        zip: zipCode,
      });

      const response = await fetch(`${API_BASE_URL}/property/lookup?${queryParams}`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success && result.data) {
          setPropertyDetails(result.data);
        }
      }
    } catch (err) {
      console.error('Property lookup error:', err);
      // Not a fatal error - we can proceed without property data
    } finally {
      setIsLoading(false);
    }
  };

  const handleConfirm = async () => {
    setIsSubmitting(true);
    setError(null);

    try {
      const addressData = {
        addressLine1: street,
        city,
        state,
        zipCode,
      };

      // If we have pending social auth, complete that registration
      if (pendingSocialAuth) {
        const result = await completeSocialRegistration({
          email: pendingSocialAuth.email || email,
          firstName: firstName || pendingSocialAuth.firstName,
          lastName: lastName || pendingSocialAuth.lastName,
          address: addressData,
          propertyDetails, // Pass property data to backend
        });

        if (result.success) {
          // Navigate to completion
          router.replace('/(onboarding)/complete');
        } else {
          setError(result.error || 'Failed to complete registration');
        }
      } else {
        // No pending social auth - shouldn't happen in normal flow
        Alert.alert('Error', 'Please start registration again');
        router.replace('/(auth)/register');
      }
    } catch (err: any) {
      setError(err.message || 'Something went wrong');
    } finally {
      setIsSubmitting(false);
    }
  };

  const formatHeatingInfo = () => {
    if (!propertyDetails?.heatingFuel && !propertyDetails?.heatingType) {
      return 'Unknown';
    }
    const fuel = propertyDetails.heatingFuel || '';
    const type = propertyDetails.heatingType || '';
    return `${fuel} ${type}`.trim() || 'Unknown';
  };

  const PropertyRow = ({
    icon,
    label,
    value,
  }: {
    icon: string;
    label: string;
    value: string | number | null | undefined;
  }) => (
    <View style={styles.propertyRow}>
      <View style={styles.propertyIcon}>
        <Ionicons name={icon as any} size={20} color={colors.haven.purple[500]} />
      </View>
      <Text style={styles.propertyLabel}>{label}</Text>
      <Text style={styles.propertyValue}>{value || '—'}</Text>
    </View>
  );

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Header */}
        <View style={styles.header}>
          <Image
            source={require('../../assets/icon.png')}
            style={styles.logo}
            resizeMode="contain"
          />
          <Text style={styles.title}>Does this look right?</Text>
          <Text style={styles.subtitle}>
            We found these details about your property. You can update them anytime.
          </Text>
        </View>

        {/* Address Card */}
        <View style={styles.addressCard}>
          <Ionicons name="home" size={24} color={colors.haven.purple[500]} />
          <View style={styles.addressText}>
            <Text style={styles.addressStreet}>{street}</Text>
            <Text style={styles.addressCity}>{city}, {state} {zipCode}</Text>
          </View>
          <TouchableOpacity onPress={() => router.back()}>
            <Text style={styles.editLink}>Edit</Text>
          </TouchableOpacity>
        </View>

        {/* Property Details Card */}
        <View style={styles.card}>
          {isLoading ? (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color={colors.haven.purple[500]} />
              <Text style={styles.loadingText}>Looking up property details...</Text>
            </View>
          ) : propertyDetails ? (
            <>
              <View style={styles.autoFilledBadge}>
                <Ionicons name="sparkles" size={14} color={colors.haven.purple[600]} />
                <Text style={styles.autoFilledText}>Auto-filled from public records</Text>
              </View>

              <View style={styles.propertyGrid}>
                <PropertyRow
                  icon="bed-outline"
                  label="Bedrooms"
                  value={propertyDetails.bedrooms}
                />
                <PropertyRow
                  icon="water-outline"
                  label="Bathrooms"
                  value={propertyDetails.bathrooms}
                />
                <PropertyRow
                  icon="resize-outline"
                  label="Square Feet"
                  value={propertyDetails.squareFeet?.toLocaleString()}
                />
                <PropertyRow
                  icon="calendar-outline"
                  label="Year Built"
                  value={propertyDetails.yearBuilt}
                />
                <PropertyRow
                  icon="flame-outline"
                  label="Heating"
                  value={formatHeatingInfo()}
                />
                <PropertyRow
                  icon="snow-outline"
                  label="Cooling"
                  value={propertyDetails.coolingType}
                />
                <PropertyRow
                  icon="water"
                  label="Water"
                  value={propertyDetails.waterType}
                />
                <PropertyRow
                  icon="leaf-outline"
                  label="Sewer"
                  value={propertyDetails.sewerType}
                />
                {propertyDetails.garageSpaces && (
                  <PropertyRow
                    icon="car-outline"
                    label="Garage"
                    value={`${propertyDetails.garageSpaces} car`}
                  />
                )}
                {propertyDetails.pool && (
                  <PropertyRow
                    icon="water-outline"
                    label="Pool"
                    value="Yes"
                  />
                )}
              </View>
            </>
          ) : (
            <View style={styles.noDataContainer}>
              <Ionicons name="information-circle-outline" size={32} color={colors.haven.purple[400]} />
              <Text style={styles.noDataText}>
                We couldn't find detailed records for this property.
                Don't worry—Alfred will help you fill in the details!
              </Text>
            </View>
          )}
        </View>

        {/* What Happens Next */}
        <View style={styles.nextStepsCard}>
          <Text style={styles.nextStepsTitle}>What happens next?</Text>
          <View style={styles.nextStep}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>1</Text>
            </View>
            <Text style={styles.stepText}>
              Alfred will ask a few questions to complete your home profile
            </Text>
          </View>
          <View style={styles.nextStep}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>2</Text>
            </View>
            <Text style={styles.stepText}>
              We'll create personalized maintenance reminders based on your systems
            </Text>
          </View>
          <View style={styles.nextStep}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>3</Text>
            </View>
            <Text style={styles.stepText}>
              Connect your bills to automate payments and tracking
            </Text>
          </View>
        </View>

        {/* Error Message */}
        {error && (
          <View style={styles.errorContainer}>
            <Ionicons name="alert-circle" size={20} color={colors.status.error} />
            <Text style={styles.errorText}>{error}</Text>
          </View>
        )}

        {/* Confirm Button */}
        <TouchableOpacity
          style={[styles.button, isSubmitting && styles.buttonDisabled]}
          onPress={handleConfirm}
          disabled={isSubmitting || isLoading}
        >
          {isSubmitting ? (
            <ActivityIndicator color={colors.white} />
          ) : (
            <>
              <Text style={styles.buttonText}>Looks Good!</Text>
              <Ionicons name="checkmark-circle" size={20} color={colors.white} />
            </>
          )}
        </TouchableOpacity>

        {/* Back Button */}
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={20} color={colors.haven.purple[600]} />
          <Text style={styles.backButtonText}>Change Address</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.haven.purple[50],
  },
  scrollContent: {
    flexGrow: 1,
    padding: spacing[6],
  },
  header: {
    alignItems: 'center',
    marginBottom: spacing[5],
  },
  logo: {
    width: 64,
    height: 64,
    borderRadius: 16,
    marginBottom: spacing[3],
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: colors.haven.purple[900],
    marginBottom: spacing[2],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.purple[500],
    textAlign: 'center',
    lineHeight: 22,
  },
  addressCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
    gap: spacing[3],
  },
  addressText: {
    flex: 1,
  },
  addressStreet: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
  },
  addressCity: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    marginTop: 2,
  },
  editLink: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    marginBottom: spacing[4],
  },
  loadingContainer: {
    alignItems: 'center',
    paddingVertical: spacing[8],
  },
  loadingText: {
    marginTop: spacing[3],
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
  },
  autoFilledBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.purple[50],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    alignSelf: 'flex-start',
    marginBottom: spacing[4],
    gap: spacing[1],
  },
  autoFilledText: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  propertyGrid: {
    gap: spacing[3],
  },
  propertyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.haven.purple[100],
  },
  propertyIcon: {
    width: 32,
  },
  propertyLabel: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
  },
  propertyValue: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[900],
  },
  noDataContainer: {
    alignItems: 'center',
    paddingVertical: spacing[6],
  },
  noDataText: {
    marginTop: spacing[3],
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    textAlign: 'center',
    lineHeight: 20,
  },
  nextStepsCard: {
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.lg,
    padding: spacing[5],
    marginBottom: spacing[6],
  },
  nextStepsTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
    marginBottom: spacing[4],
  },
  nextStep: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: spacing[3],
    gap: spacing[3],
  },
  stepNumber: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: colors.haven.purple[500],
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepNumberText: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.white,
  },
  stepText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    lineHeight: 20,
  },
  errorContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.status.errorLight,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
    gap: spacing[2],
  },
  errorText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.status.error,
  },
  button: {
    backgroundColor: colors.haven.purple[900],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
  backButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing[4],
    gap: spacing[2],
  },
  backButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
  },
});
