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
  Switch,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useOnboarding, type HomeBasicsData } from '../../../src/contexts/onboarding-context';
import { getApiClient } from '../../../src/lib/api';
import { colors, spacing, typography, borderRadius } from '../../../src/lib/theme';
import type { PropertyType, PropertyFeatures } from '@haven/core';
import { PROPERTY_TYPE_OPTIONS, PROPERTY_FEATURE_OPTIONS } from '@haven/core';

const DEFAULT_FEATURES: PropertyFeatures = {
  hasCentralAc: false,
  hasGasHeat: false,
  hasOilHeat: false,
  hasFireplace: false,
  hasSeptic: false,
  hasWellWater: false,
  hasPool: false,
  hasGenerator: false,
  hasLawn: false,
  hasDriveway: false,
};

export default function OnboardingHomeBasicsScreen() {
  const router = useRouter();
  const { setHouseholdId, setHomeBasics } = useOnboarding();
  const api = getApiClient();

  // Form state
  const [name, setName] = useState('');
  const [propertyType, setPropertyType] = useState<PropertyType>('SINGLE_FAMILY');
  const [addressLine1, setAddressLine1] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [postalCode, setPostalCode] = useState('');
  const [yearBuilt, setYearBuilt] = useState('');
  const [squareFeet, setSquareFeet] = useState('');
  const [bedrooms, setBedrooms] = useState('');
  const [bathrooms, setBathrooms] = useState('');
  const [features, setFeatures] = useState<PropertyFeatures>(DEFAULT_FEATURES);
  const [isLoading, setIsLoading] = useState(false);

  const toggleFeature = (key: keyof PropertyFeatures) => {
    setFeatures((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handleContinue = async () => {
    if (!name.trim() || !addressLine1.trim() || !city.trim() || !state.trim() || !postalCode.trim()) {
      Alert.alert('Error', 'Please fill in all required fields');
      return;
    }

    setIsLoading(true);
    try {
      // Create household
      const household = await api.createHousehold({
        name: name.trim(),
        description: `${propertyType} in ${city.trim()}, ${state.trim()}`,
      });

      setHouseholdId(household.id);

      // Create home profile with features in notes
      await api.upsertHomeProfile(household.id, {
        propertyType,
        addressLine1: addressLine1.trim(),
        city: city.trim(),
        state: state.trim(),
        postalCode: postalCode.trim(),
        country: 'US',
        yearBuilt: yearBuilt ? parseInt(yearBuilt, 10) : undefined,
        squareFeet: squareFeet ? parseInt(squareFeet, 10) : undefined,
        bedrooms: bedrooms ? parseInt(bedrooms, 10) : undefined,
        bathrooms: bathrooms ? parseFloat(bathrooms) : undefined,
        notes: JSON.stringify({ features }),
      });

      // Save to context
      const homeBasicsData: HomeBasicsData = {
        name: name.trim(),
        propertyType,
        addressLine1: addressLine1.trim(),
        city: city.trim(),
        state: state.trim(),
        postalCode: postalCode.trim(),
        yearBuilt: yearBuilt ? parseInt(yearBuilt, 10) : undefined,
        squareFeet: squareFeet ? parseInt(squareFeet, 10) : undefined,
        bedrooms: bedrooms ? parseInt(bedrooms, 10) : undefined,
        bathrooms: bathrooms ? parseFloat(bathrooms) : undefined,
        features,
      };
      setHomeBasics(homeBasicsData);

      // Navigate to next step
      router.push('/(auth)/onboarding/bills');
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to save property details');
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
          showsVerticalScrollIndicator={false}
        >
          {/* Progress indicator */}
          <View style={styles.progressContainer}>
            <View style={styles.progressBar}>
              <View style={[styles.progressFill, { width: '20%' }]} />
            </View>
            <Text style={styles.progressText}>Step 1 of 5</Text>
          </View>

          <View style={styles.header}>
            <Text style={styles.title}>Tell us about your home</Text>
            <Text style={styles.subtitle}>
              We'll use this to personalize your maintenance schedule
            </Text>
          </View>

          {/* Basic Info Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Basic Information</Text>

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
                {PROPERTY_TYPE_OPTIONS.slice(0, 6).map((type) => (
                  <TouchableOpacity
                    key={type.value}
                    style={[
                      styles.typeButton,
                      propertyType === type.value && styles.typeButtonActive,
                    ]}
                    onPress={() => setPropertyType(type.value as PropertyType)}
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
          </View>

          {/* Address Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Address</Text>

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

            <View style={styles.row}>
              <View style={[styles.inputContainer, { flex: 1 }]}>
                <Text style={styles.label}>ZIP Code *</Text>
                <TextInput
                  style={styles.input}
                  placeholder="12345"
                  placeholderTextColor={colors.slate[400]}
                  value={postalCode}
                  onChangeText={setPostalCode}
                  keyboardType="number-pad"
                  maxLength={10}
                />
              </View>
              <View style={[styles.inputContainer, { flex: 1 }]}>
                <Text style={styles.label}>Year Built</Text>
                <TextInput
                  style={styles.input}
                  placeholder="1990"
                  placeholderTextColor={colors.slate[400]}
                  value={yearBuilt}
                  onChangeText={setYearBuilt}
                  keyboardType="number-pad"
                  maxLength={4}
                />
              </View>
            </View>
          </View>

          {/* Details Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Property Details</Text>

            <View style={styles.row}>
              <View style={[styles.inputContainer, { flex: 1 }]}>
                <Text style={styles.label}>Sq. Feet</Text>
                <TextInput
                  style={styles.input}
                  placeholder="2000"
                  placeholderTextColor={colors.slate[400]}
                  value={squareFeet}
                  onChangeText={setSquareFeet}
                  keyboardType="number-pad"
                />
              </View>
              <View style={[styles.inputContainer, { flex: 1 }]}>
                <Text style={styles.label}>Bedrooms</Text>
                <TextInput
                  style={styles.input}
                  placeholder="3"
                  placeholderTextColor={colors.slate[400]}
                  value={bedrooms}
                  onChangeText={setBedrooms}
                  keyboardType="number-pad"
                />
              </View>
              <View style={[styles.inputContainer, { flex: 1 }]}>
                <Text style={styles.label}>Bathrooms</Text>
                <TextInput
                  style={styles.input}
                  placeholder="2"
                  placeholderTextColor={colors.slate[400]}
                  value={bathrooms}
                  onChangeText={setBathrooms}
                  keyboardType="decimal-pad"
                />
              </View>
            </View>
          </View>

          {/* Features Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Property Features</Text>
            <Text style={styles.sectionSubtitle}>
              Select all that apply - helps create your maintenance plan
            </Text>

            {PROPERTY_FEATURE_OPTIONS.map((feature) => (
              <TouchableOpacity
                key={feature.key}
                style={styles.featureRow}
                onPress={() => toggleFeature(feature.key as keyof PropertyFeatures)}
              >
                <View style={styles.featureInfo}>
                  <Text style={styles.featureLabel}>{feature.label}</Text>
                  <Text style={styles.featureDesc}>{feature.description}</Text>
                </View>
                <Switch
                  value={features[feature.key as keyof PropertyFeatures]}
                  onValueChange={() => toggleFeature(feature.key as keyof PropertyFeatures)}
                  trackColor={{ false: colors.slate[200], true: colors.primary[200] }}
                  thumbColor={
                    features[feature.key as keyof PropertyFeatures]
                      ? colors.primary[600]
                      : colors.slate[400]
                  }
                />
              </TouchableOpacity>
            ))}
          </View>

          {/* Continue Button */}
          <TouchableOpacity
            style={[styles.button, isLoading && styles.buttonDisabled]}
            onPress={handleContinue}
            disabled={isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color={colors.white} />
            ) : (
              <Text style={styles.buttonText}>Continue</Text>
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
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  progressContainer: {
    marginBottom: spacing[4],
  },
  progressBar: {
    height: 4,
    backgroundColor: colors.slate[200],
    borderRadius: 2,
    marginBottom: spacing[2],
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.primary[600],
    borderRadius: 2,
  },
  progressText: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    textAlign: 'center',
  },
  header: {
    marginBottom: spacing[4],
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
    marginBottom: spacing[1],
  },
  subtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    lineHeight: 20,
  },
  section: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginBottom: spacing[4],
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[800],
    marginBottom: spacing[3],
  },
  sectionSubtitle: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginBottom: spacing[3],
    marginTop: -spacing[2],
  },
  inputContainer: {
    marginBottom: spacing[3],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
    marginBottom: spacing[1],
  },
  input: {
    backgroundColor: colors.slate[50],
    borderWidth: 1,
    borderColor: colors.slate[200],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
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
    paddingHorizontal: spacing[3],
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
  featureRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[100],
  },
  featureInfo: {
    flex: 1,
    marginRight: spacing[3],
  },
  featureLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[800],
  },
  featureDesc: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  button: {
    backgroundColor: colors.primary[600],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    alignItems: 'center',
    marginTop: spacing[2],
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
