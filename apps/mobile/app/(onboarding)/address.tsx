import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Image,
  ActivityIndicator,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { AddressAutocomplete, AddressDetails } from '../../src/components/forms/AddressAutocomplete';
import { useAuth } from '../../src/contexts/auth-context';
import { colors, spacing, typography, borderRadius } from '../../src/lib/theme';

export default function AddressScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();
  const { pendingSocialAuth } = useAuth();

  // Get name from social auth or params
  const firstName = pendingSocialAuth?.firstName || (params.firstName as string) || '';
  const lastName = pendingSocialAuth?.lastName || (params.lastName as string) || '';
  const email = pendingSocialAuth?.email || (params.email as string) || '';

  const [selectedAddress, setSelectedAddress] = useState<AddressDetails | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAddressSelect = (address: AddressDetails) => {
    setSelectedAddress(address);
    setError(null);
  };

  const handleContinue = async () => {
    if (!selectedAddress) {
      setError('Please select your address from the dropdown');
      return;
    }

    setIsLoading(true);

    // Build the street address
    const street = selectedAddress.streetNumber
      ? `${selectedAddress.streetNumber} ${selectedAddress.street || ''}`
      : selectedAddress.street || '';

    // Navigate to property confirmation with address data
    router.push({
      pathname: '/(onboarding)/confirm-property',
      params: {
        street,
        city: selectedAddress.city || '',
        state: selectedAddress.state || '',
        zipCode: selectedAddress.postalCode || '',
        formatted: selectedAddress.formattedAddress,
        latitude: selectedAddress.latitude?.toString() || '',
        longitude: selectedAddress.longitude?.toString() || '',
        firstName,
        lastName,
        email,
      },
    });

    setIsLoading(false);
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        {/* Header */}
        <View style={styles.header}>
          <Image
            source={require('../../assets/icon.png')}
            style={styles.logo}
            resizeMode="contain"
          />
          <Text style={styles.title}>Where's home?</Text>
          <Text style={styles.subtitle}>
            {firstName ? `Hi ${firstName}! ` : ''}Enter your address and we'll
            automatically set up your home profile.
          </Text>
        </View>

        {/* Address Input */}
        <View style={styles.card}>
          <AddressAutocomplete
            label="Property Address"
            onAddressSelect={handleAddressSelect}
            error={error || undefined}
            placeholder="Start typing your address..."
          />

          {/* Selected Address Preview */}
          {selectedAddress && (
            <View style={styles.selectedPreview}>
              <Ionicons
                name="checkmark-circle"
                size={20}
                color="#10b981"
              />
              <Text style={styles.selectedText}>
                {selectedAddress.formattedAddress}
              </Text>
            </View>
          )}

          {/* What we'll do */}
          <View style={styles.infoBox}>
            <Ionicons
              name="sparkles"
              size={20}
              color={colors.haven.champagne[500]}
            />
            <Text style={styles.infoText}>
              We'll look up your property details like bedrooms, bathrooms,
              heating type, and more to personalize your experience.
            </Text>
          </View>

          {/* Continue Button */}
          <TouchableOpacity
            style={[
              styles.button,
              (!selectedAddress || isLoading) && styles.buttonDisabled,
            ]}
            onPress={handleContinue}
            disabled={!selectedAddress || isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color={colors.white} />
            ) : (
              <>
                <Text style={styles.buttonText}>Continue</Text>
                <Ionicons name="arrow-forward" size={20} color={colors.white} />
              </>
            )}
          </TouchableOpacity>
        </View>

        {/* Privacy Note */}
        <View style={styles.privacyContainer}>
          <Ionicons name="lock-closed" size={12} color={colors.haven.navy[400]} />
          <Text style={styles.privacyNote}>
            Your information is secure and never shared.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.haven.navy[50],
  },
  scrollContent: {
    flexGrow: 1,
    padding: spacing[6],
  },
  header: {
    alignItems: 'center',
    marginBottom: spacing[6],
    marginTop: spacing[4],
  },
  logo: {
    width: 80,
    height: 80,
    borderRadius: 20,
    marginBottom: spacing[4],
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.haven.navy[900],
    marginBottom: spacing[2],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[500],
    textAlign: 'center',
    lineHeight: 24,
    paddingHorizontal: spacing[4],
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[6],
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  selectedPreview: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f0fdf4',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginTop: spacing[3],
    gap: spacing[2],
  },
  selectedText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: '#166534',
  },
  infoBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.haven.champagne[50],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
    gap: spacing[3],
  },
  infoText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[600],
    lineHeight: 20,
  },
  button: {
    backgroundColor: colors.haven.navy[900],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    marginTop: spacing[6],
  },
  buttonDisabled: {
    opacity: 0.5,
  },
  buttonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
  privacyContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing[6],
    gap: spacing[1],
  },
  privacyNote: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.navy[400],
  },
});
