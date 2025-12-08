import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../../src/contexts/auth-context';
import { getApiClient } from '../../src/lib/api';
import { colors, spacing, typography, borderRadius } from '../../src/lib/theme';
import type { PropertyType } from '@haven/core';

const PROPERTY_TYPES: { value: PropertyType; label: string }[] = [
  { value: 'SINGLE_FAMILY', label: 'Single Family' },
  { value: 'TOWNHOUSE', label: 'Townhouse' },
  { value: 'CONDO', label: 'Condo' },
  { value: 'APARTMENT', label: 'Apartment' },
  { value: 'MULTI_FAMILY', label: 'Multi-Family' },
  { value: 'OTHER', label: 'Other' },
];

export default function OnboardingScreen() {
  const router = useRouter();
  const { refreshHouseholds } = useAuth();
  const api = getApiClient();

  const [name, setName] = useState('');
  const [propertyType, setPropertyType] = useState<PropertyType>('SINGLE_FAMILY');
  const [addressLine1, setAddressLine1] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [postalCode, setPostalCode] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleComplete = async () => {
    if (!name.trim() || !addressLine1.trim() || !city.trim() || !state.trim() || !postalCode.trim()) {
      Alert.alert('Error', 'Please fill in all required fields');
      return;
    }

    setIsLoading(true);
    try {
      // Create household
      const household = await api.createHousehold({
        name: name.trim(),
        description: `${propertyType} home`,
      });

      // Create home profile
      await api.upsertHomeProfile(household.id, {
        propertyType,
        addressLine1: addressLine1.trim(),
        city: city.trim(),
        state: state.trim(),
        postalCode: postalCode.trim(),
        country: 'USA',
      });

      // Refresh and navigate
      await refreshHouseholds();
      router.replace('/(tabs)');
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to create home');
    } finally {
      setIsLoading(false);
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
        >
          <View style={styles.header}>
            <Text style={styles.title}>Set Up Your Home</Text>
            <Text style={styles.subtitle}>
              Tell us about your home so we can help you manage it better
            </Text>
          </View>

          <View style={styles.form}>
            <View style={styles.inputContainer}>
              <Text style={styles.label}>Home Name *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g., My House, Beach Condo"
                placeholderTextColor={colors.slate[400]}
                value={name}
                onChangeText={setName}
              />
            </View>

            <View style={styles.inputContainer}>
              <Text style={styles.label}>Property Type *</Text>
              <View style={styles.typeGrid}>
                {PROPERTY_TYPES.map((type) => (
                  <TouchableOpacity
                    key={type.value}
                    style={[
                      styles.typeButton,
                      propertyType === type.value && styles.typeButtonActive,
                    ]}
                    onPress={() => setPropertyType(type.value)}
                  >
                    <Text
                      style={[
                        styles.typeButtonText,
                        propertyType === type.value && styles.typeButtonTextActive,
                      ]}
                    >
                      {type.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <View style={styles.inputContainer}>
              <Text style={styles.label}>Street Address *</Text>
              <TextInput
                style={styles.input}
                placeholder="123 Main Street"
                placeholderTextColor={colors.slate[400]}
                value={addressLine1}
                onChangeText={setAddressLine1}
              />
            </View>

            <View style={styles.row}>
              <View style={[styles.inputContainer, { flex: 2 }]}>
                <Text style={styles.label}>City *</Text>
                <TextInput
                  style={styles.input}
                  placeholder="City"
                  placeholderTextColor={colors.slate[400]}
                  value={city}
                  onChangeText={setCity}
                />
              </View>
              <View style={[styles.inputContainer, { flex: 1 }]}>
                <Text style={styles.label}>State *</Text>
                <TextInput
                  style={styles.input}
                  placeholder="CA"
                  placeholderTextColor={colors.slate[400]}
                  value={state}
                  onChangeText={setState}
                  autoCapitalize="characters"
                  maxLength={2}
                />
              </View>
            </View>

            <View style={styles.inputContainer}>
              <Text style={styles.label}>ZIP Code *</Text>
              <TextInput
                style={[styles.input, { width: 120 }]}
                placeholder="12345"
                placeholderTextColor={colors.slate[400]}
                value={postalCode}
                onChangeText={setPostalCode}
                keyboardType="number-pad"
                maxLength={10}
              />
            </View>
          </View>

          <TouchableOpacity
            style={[styles.button, isLoading && styles.buttonDisabled]}
            onPress={handleComplete}
            disabled={isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color={colors.white} />
            ) : (
              <Text style={styles.buttonText}>Complete Setup</Text>
            )}
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    padding: spacing[6],
  },
  header: {
    marginBottom: spacing[6],
  },
  title: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
    marginBottom: spacing[2],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
    lineHeight: 24,
  },
  form: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[6],
    marginBottom: spacing[6],
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  inputContainer: {
    marginBottom: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
    marginBottom: spacing[2],
  },
  input: {
    backgroundColor: colors.slate[50],
    borderWidth: 1,
    borderColor: colors.slate[200],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
  },
  row: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  typeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  typeButton: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.slate[200],
    backgroundColor: colors.white,
  },
  typeButtonActive: {
    borderColor: colors.primary[600],
    backgroundColor: colors.primary[50],
  },
  typeButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
  },
  typeButtonTextActive: {
    color: colors.primary[700],
    fontWeight: typography.fontWeights.medium,
  },
  button: {
    backgroundColor: colors.primary[600],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    alignItems: 'center',
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  buttonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
});
