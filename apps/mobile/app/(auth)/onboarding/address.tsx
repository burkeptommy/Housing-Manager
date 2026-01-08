import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useOnboarding } from '../../../src/contexts/onboarding-context';
import { Button, Card } from '../../../src/components';
import { AddressAutocomplete, type AddressDetails } from '../../../src/components/forms/AddressAutocomplete';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL, getAccessToken } from '../../../src/lib/api';

export default function OnboardingAddressScreen() {
  const router = useRouter();
  const { setPropertyData, setStep, setIsLoadingAttom, setAttomError } = useOnboarding();
  const [selectedAddress, setSelectedAddress] = useState<AddressDetails | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const handleAddressSelect = async (address: AddressDetails) => {
    setSelectedAddress(address);
    setError('');
  };

  const handleContinue = async () => {
    if (!selectedAddress) {
      setError('Please select your address');
      return;
    }

    setIsLoading(true);
    setIsLoadingAttom(true);
    setAttomError(null);

    try {
      // Get auth token for API call
      const token = await getAccessToken();

      // Call ATTOM API via our backend
      const response = await fetch(`${API_BASE_URL}/attom/property-lookup`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({
          address: selectedAddress.formattedAddress,
          city: selectedAddress.city,
          state: selectedAddress.state,
          postalCode: selectedAddress.postalCode,
        }),
      });

      let attomData: any = {};

      if (response.ok) {
        attomData = await response.json();
      }

      // Combine address with ATTOM data
      const propertyData = {
        addressLine1: `${selectedAddress.streetNumber || ''} ${selectedAddress.street || ''}`.trim(),
        city: selectedAddress.city || '',
        state: selectedAddress.state || '',
        postalCode: selectedAddress.postalCode || '',
        latitude: selectedAddress.latitude,
        longitude: selectedAddress.longitude,
        propertyType: attomData.propertyType || 'SINGLE_FAMILY',
        yearBuilt: attomData.yearBuilt,
        squareFeet: attomData.squareFeet,
        bedrooms: attomData.bedrooms,
        bathrooms: attomData.bathrooms,
        lotSize: attomData.lotSize,
        stories: attomData.stories,
        hvacType: attomData.hvacType,
        heatingFuel: attomData.heatingFuel,
        hasPool: attomData.hasPool,
        hasFireplace: attomData.hasFireplace,
        roofType: attomData.roofType,
        roofAge: attomData.roofAge,
        foundationType: attomData.foundationType,
        electricProvider: attomData.utilities?.electric,
        gasProvider: attomData.utilities?.gas,
        waterProvider: attomData.utilities?.water,
        trashProvider: attomData.utilities?.trash,
      };

      setPropertyData(propertyData);
      setStep('property');
      router.push('/(auth)/onboarding/property');
    } catch (err: any) {
      console.error('ATTOM lookup error:', err);

      // Even if ATTOM fails, allow user to continue with manual entry
      const propertyData = {
        addressLine1: `${selectedAddress.streetNumber || ''} ${selectedAddress.street || ''}`.trim(),
        city: selectedAddress.city || '',
        state: selectedAddress.state || '',
        postalCode: selectedAddress.postalCode || '',
        latitude: selectedAddress.latitude,
        longitude: selectedAddress.longitude,
        propertyType: 'SINGLE_FAMILY',
      };

      setPropertyData(propertyData);
      setAttomError('Could not auto-detect property details. Please enter manually.');
      setStep('property');
      router.push('/(auth)/onboarding/property');
    } finally {
      setIsLoading(false);
      setIsLoadingAttom(false);
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Progress */}
          <View style={styles.progress}>
            <View style={styles.progressBar}>
              <View style={[styles.progressFill, { width: '20%' }]} />
            </View>
            <Text style={styles.progressText}>Step 1 of 5</Text>
          </View>

          {/* Header */}
          <View style={styles.header}>
            <View style={styles.iconContainer}>
              <Ionicons name="home" size={32} color={colors.haven.champagne[500]} />
            </View>
            <Text style={styles.title}>Where's your home?</Text>
            <Text style={styles.subtitle}>
              We'll use this to set up your property profile and find local service providers
            </Text>
          </View>

          {/* Address Input */}
          <Card style={styles.card}>
            <AddressAutocomplete
              label="Home Address"
              placeholder="Start typing your address..."
              onAddressSelect={handleAddressSelect}
              error={error && !selectedAddress ? error : undefined}
            />

            {selectedAddress && (
              <View style={styles.selectedAddress}>
                <Ionicons
                  name="checkmark-circle"
                  size={20}
                  color={colors.status.success}
                />
                <Text style={styles.selectedAddressText}>
                  {selectedAddress.formattedAddress}
                </Text>
              </View>
            )}

            <View style={styles.infoBox}>
              <Ionicons
                name="sparkles"
                size={20}
                color={colors.haven.champagne[500]}
              />
              <Text style={styles.infoText}>
                We'll automatically detect your property details, HVAC systems, and local utilities
              </Text>
            </View>
          </Card>

          {/* Continue Button */}
          <Button
            title={isLoading ? 'Looking up property...' : 'Continue'}
            onPress={handleContinue}
            loading={isLoading}
            disabled={!selectedAddress}
            fullWidth
          />
        </ScrollView>
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
    padding: spacing[5],
    paddingBottom: spacing[8],
  },
  progress: {
    marginBottom: spacing[6],
  },
  progressBar: {
    height: 4,
    backgroundColor: colors.haven.navy[100],
    borderRadius: 2,
    marginBottom: spacing[2],
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.haven.champagne[500],
    borderRadius: 2,
  },
  progressText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    textAlign: 'center',
  },
  header: {
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  iconContainer: {
    width: 64,
    height: 64,
    borderRadius: borderRadius.xl,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  title: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
    textAlign: 'center',
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
    lineHeight: 24,
    paddingHorizontal: spacing[4],
  },
  card: {
    marginBottom: spacing[6],
    padding: spacing[5],
  },
  selectedAddress: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.status.successLight,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginTop: spacing[2],
  },
  selectedAddressText: {
    flex: 1,
    marginLeft: spacing[2],
    fontSize: typography.fontSizes.sm,
    color: colors.status.success,
    fontWeight: typography.fontWeights.medium,
  },
  infoBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.haven.champagne[50],
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
    gap: spacing[2],
  },
  infoText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    lineHeight: 20,
  },
});
