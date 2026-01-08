# Haven Mobile: M03 - Magic Onboarding

**Created:** December 29, 2024  
**Priority:** P0 - Core user experience  
**Estimated Time:** 4-5 hours  
**Dependencies:** M01, M02 complete

---

## CRITICAL RULES

1. **Same "10-minute magic" as web** - Users should have populated dashboard in minutes
2. **Address autocomplete is essential** - Use Google Places API
3. **Auto-populate property data** - Use ATTOM API via our backend
4. **Minimize typing** - Use selections, toggles, autocomplete whenever possible
5. **Show value immediately** - Preview detected data before confirming

---

## Overview

The mobile onboarding should feel magical:
1. User enters address → autocomplete helps
2. Address verified → ATTOM populates property data
3. User confirms/adjusts → data saved
4. Optional: Connect bank (Plaid) for bill detection
5. Select subscription tier
6. Welcome → Dashboard with populated data

**Goal:** Zero manual property data entry. Everything auto-detected.

---

## PHASE 1: Install Dependencies

### Task 1.1: Install Google Places Autocomplete

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Google Places autocomplete
pnpm add react-native-google-places-autocomplete

# For better address display
pnpm add expo-location
```

---

## PHASE 2: Create Address Autocomplete Component

### Task 2.1: Create AddressAutocomplete Component

Create `apps/mobile/src/components/forms/AddressAutocomplete.tsx`:

```typescript
import React, { useRef, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  FlatList,
  ActivityIndicator,
  Keyboard,
  ViewStyle,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius, shadows } from '../../lib/theme';
import { GOOGLE_PLACES_API_KEY } from '../../lib/config';

interface AddressPrediction {
  place_id: string;
  description: string;
  structured_formatting: {
    main_text: string;
    secondary_text: string;
  };
}

interface AddressDetails {
  formattedAddress: string;
  streetNumber?: string;
  street?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  country?: string;
  latitude?: number;
  longitude?: number;
}

interface AddressAutocompleteProps {
  label?: string;
  placeholder?: string;
  value?: string;
  onAddressSelect: (address: AddressDetails) => void;
  error?: string;
  containerStyle?: ViewStyle;
}

export function AddressAutocomplete({
  label,
  placeholder = 'Enter your address',
  value = '',
  onAddressSelect,
  error,
  containerStyle,
}: AddressAutocompleteProps) {
  const [query, setQuery] = useState(value);
  const [predictions, setPredictions] = useState<AddressPrediction[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isFocused, setIsFocused] = useState(false);
  const [showPredictions, setShowPredictions] = useState(false);
  const debounceRef = useRef<NodeJS.Timeout | null>(null);

  const searchPlaces = async (text: string) => {
    if (text.length < 3) {
      setPredictions([]);
      return;
    }

    setIsLoading(true);

    try {
      const response = await fetch(
        `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(
          text
        )}&types=address&components=country:us&key=${GOOGLE_PLACES_API_KEY}`
      );

      const data = await response.json();

      if (data.predictions) {
        setPredictions(data.predictions);
        setShowPredictions(true);
      }
    } catch (err) {
      console.error('Places autocomplete error:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleTextChange = (text: string) => {
    setQuery(text);

    // Debounce API calls
    if (debounceRef.current) {
      clearTimeout(debounceRef.current);
    }

    debounceRef.current = setTimeout(() => {
      searchPlaces(text);
    }, 300);
  };

  const getPlaceDetails = async (placeId: string): Promise<AddressDetails | null> => {
    try {
      const response = await fetch(
        `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=formatted_address,address_components,geometry&key=${GOOGLE_PLACES_API_KEY}`
      );

      const data = await response.json();

      if (data.result) {
        const result = data.result;
        const components = result.address_components || [];

        const getComponent = (type: string) => {
          const component = components.find((c: any) => c.types.includes(type));
          return component?.long_name || component?.short_name;
        };

        const getComponentShort = (type: string) => {
          const component = components.find((c: any) => c.types.includes(type));
          return component?.short_name;
        };

        return {
          formattedAddress: result.formatted_address,
          streetNumber: getComponent('street_number'),
          street: getComponent('route'),
          city: getComponent('locality') || getComponent('sublocality'),
          state: getComponentShort('administrative_area_level_1'),
          postalCode: getComponent('postal_code'),
          country: getComponentShort('country'),
          latitude: result.geometry?.location?.lat,
          longitude: result.geometry?.location?.lng,
        };
      }

      return null;
    } catch (err) {
      console.error('Place details error:', err);
      return null;
    }
  };

  const handleSelectPrediction = async (prediction: AddressPrediction) => {
    Keyboard.dismiss();
    setQuery(prediction.description);
    setShowPredictions(false);
    setPredictions([]);
    setIsLoading(true);

    const details = await getPlaceDetails(prediction.place_id);
    setIsLoading(false);

    if (details) {
      onAddressSelect(details);
    }
  };

  const handleClear = () => {
    setQuery('');
    setPredictions([]);
    setShowPredictions(false);
  };

  return (
    <View style={[styles.container, containerStyle]}>
      {label && <Text style={styles.label}>{label}</Text>}

      <View
        style={[
          styles.inputContainer,
          isFocused && styles.inputFocused,
          error && styles.inputError,
        ]}
      >
        <Ionicons
          name="location-outline"
          size={20}
          color={colors.haven.navy[400]}
          style={styles.icon}
        />

        <TextInput
          style={styles.input}
          placeholder={placeholder}
          placeholderTextColor={colors.haven.navy[400]}
          value={query}
          onChangeText={handleTextChange}
          onFocus={() => {
            setIsFocused(true);
            if (predictions.length > 0) {
              setShowPredictions(true);
            }
          }}
          onBlur={() => {
            setIsFocused(false);
            // Delay hiding to allow tap on prediction
            setTimeout(() => setShowPredictions(false), 200);
          }}
          autoCapitalize="words"
          autoCorrect={false}
        />

        {isLoading && (
          <ActivityIndicator size="small" color={colors.haven.champagne[500]} />
        )}

        {query.length > 0 && !isLoading && (
          <TouchableOpacity onPress={handleClear} style={styles.clearButton}>
            <Ionicons name="close-circle" size={20} color={colors.haven.navy[400]} />
          </TouchableOpacity>
        )}
      </View>

      {error && <Text style={styles.errorText}>{error}</Text>}

      {/* Predictions dropdown */}
      {showPredictions && predictions.length > 0 && (
        <View style={styles.predictionsContainer}>
          <FlatList
            data={predictions}
            keyExtractor={(item) => item.place_id}
            keyboardShouldPersistTaps="handled"
            renderItem={({ item }) => (
              <TouchableOpacity
                style={styles.predictionItem}
                onPress={() => handleSelectPrediction(item)}
              >
                <Ionicons
                  name="location"
                  size={18}
                  color={colors.haven.champagne[500]}
                  style={styles.predictionIcon}
                />
                <View style={styles.predictionText}>
                  <Text style={styles.predictionMain}>
                    {item.structured_formatting.main_text}
                  </Text>
                  <Text style={styles.predictionSecondary}>
                    {item.structured_formatting.secondary_text}
                  </Text>
                </View>
              </TouchableOpacity>
            )}
            ItemSeparatorComponent={() => <View style={styles.separator} />}
          />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: spacing[4],
    zIndex: 100,
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[1.5],
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.background.tertiary,
    borderWidth: 1,
    borderColor: colors.border.default,
    borderRadius: borderRadius.lg,
    minHeight: 48,
    paddingHorizontal: spacing[3],
  },
  inputFocused: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.white,
  },
  inputError: {
    borderColor: colors.status.error,
  },
  icon: {
    marginRight: spacing[2],
  },
  input: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    paddingVertical: spacing[3],
  },
  clearButton: {
    padding: spacing[1],
  },
  errorText: {
    fontSize: typography.fontSizes.xs,
    color: colors.status.error,
    marginTop: spacing[1],
  },
  predictionsContainer: {
    position: 'absolute',
    top: '100%',
    left: 0,
    right: 0,
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    marginTop: spacing[1],
    maxHeight: 250,
    ...shadows.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  predictionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
  },
  predictionIcon: {
    marginRight: spacing[3],
  },
  predictionText: {
    flex: 1,
  },
  predictionMain: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  predictionSecondary: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  separator: {
    height: 1,
    backgroundColor: colors.border.light,
    marginLeft: spacing[10],
  },
});
```

---

## PHASE 3: Create Onboarding Wizard

### Task 3.1: Create Onboarding Types

Create `apps/mobile/src/types/onboarding.ts`:

```typescript
export interface PropertyData {
  // From address
  addressLine1: string;
  city: string;
  state: string;
  postalCode: string;
  latitude?: number;
  longitude?: number;

  // From ATTOM or user input
  propertyType: string;
  yearBuilt?: number;
  squareFeet?: number;
  bedrooms?: number;
  bathrooms?: number;
  lotSize?: number;
  stories?: number;

  // Systems (from ATTOM)
  hvacType?: string;
  heatingFuel?: string;
  hasPool?: boolean;
  hasFireplace?: boolean;
  roofType?: string;
  roofAge?: number;
  foundationType?: string;

  // Utilities (from ATTOM regional data)
  electricProvider?: string;
  gasProvider?: string;
  waterProvider?: string;
  trashProvider?: string;
}

export interface OnboardingState {
  step: 'address' | 'property' | 'confirm' | 'bank' | 'plan' | 'complete';
  propertyData: PropertyData | null;
  householdId: string | null;
  isLoadingAttom: boolean;
  attomError: string | null;
}
```

### Task 3.2: Create Onboarding Screen - Address Step

Create `apps/mobile/app/(auth)/onboarding/address.tsx`:

```typescript
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
import { AddressAutocomplete } from '../../../src/components/forms/AddressAutocomplete';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { getApiClient } from '../../../src/lib/api';

export default function OnboardingAddressScreen() {
  const router = useRouter();
  const { setPropertyData, setStep, setIsLoadingAttom, setAttomError } = useOnboarding();
  const [selectedAddress, setSelectedAddress] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const handleAddressSelect = async (address: any) => {
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
      const api = getApiClient();

      // Call ATTOM API via our backend
      const attomData = await api.request<any>('POST', '/attom/property-lookup', {
        address: selectedAddress.formattedAddress,
        city: selectedAddress.city,
        state: selectedAddress.state,
        postalCode: selectedAddress.postalCode,
      });

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
```

### Task 3.3: Create Property Confirmation Screen

Create `apps/mobile/app/(auth)/onboarding/property.tsx`:

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useOnboarding } from '../../../src/contexts/onboarding-context';
import { Button, Card, Badge, Input } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { getApiClient } from '../../../src/lib/api';
import { useAuth } from '../../../src/contexts/auth-context';

export default function OnboardingPropertyScreen() {
  const router = useRouter();
  const { user } = useAuth();
  const { propertyData, setPropertyData, setHouseholdId, attomError, setStep } = useOnboarding();
  const [isLoading, setIsLoading] = useState(false);
  const [isEditing, setIsEditing] = useState(false);

  // Local state for editing
  const [editedData, setEditedData] = useState(propertyData);

  const handleSave = async () => {
    if (!editedData || !user) {
      Alert.alert('Error', 'Missing property data or user');
      return;
    }

    setIsLoading(true);

    try {
      const api = getApiClient();

      // Create household
      const household = await api.createHousehold({
        name: `${editedData.city} Home`,
        description: `${editedData.addressLine1}, ${editedData.city}, ${editedData.state}`,
      });

      setHouseholdId(household.id);

      // Create home profile
      await api.upsertHomeProfile(household.id, {
        propertyType: editedData.propertyType as any,
        addressLine1: editedData.addressLine1,
        city: editedData.city,
        state: editedData.state,
        postalCode: editedData.postalCode,
        country: 'US',
        yearBuilt: editedData.yearBuilt,
        squareFeet: editedData.squareFeet,
        bedrooms: editedData.bedrooms,
        bathrooms: editedData.bathrooms,
        notes: JSON.stringify({
          lotSize: editedData.lotSize,
          hvacType: editedData.hvacType,
          heatingFuel: editedData.heatingFuel,
          hasPool: editedData.hasPool,
          hasFireplace: editedData.hasFireplace,
          roofType: editedData.roofType,
          utilities: {
            electric: editedData.electricProvider,
            gas: editedData.gasProvider,
            water: editedData.waterProvider,
            trash: editedData.trashProvider,
          },
        }),
      });

      // Update context and navigate
      setPropertyData(editedData);
      setStep('bank');
      router.push('/(auth)/onboarding/bank');
    } catch (err: any) {
      console.error('Save property error:', err);
      Alert.alert('Error', err.message || 'Failed to save property');
    } finally {
      setIsLoading(false);
    }
  };

  const formatValue = (value: any, suffix?: string) => {
    if (value === null || value === undefined) return 'Not detected';
    if (suffix) return `${value.toLocaleString()}${suffix}`;
    return value.toString();
  };

  if (!propertyData || !editedData) {
    return (
      <SafeAreaView style={styles.container}>
        <Text>No property data found</Text>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Progress */}
        <View style={styles.progress}>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: '40%' }]} />
          </View>
          <Text style={styles.progressText}>Step 2 of 5</Text>
        </View>

        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>Confirm your property</Text>
          <Text style={styles.subtitle}>
            We found the following details about your home
          </Text>
        </View>

        {/* ATTOM Warning if applicable */}
        {attomError && (
          <View style={styles.warningBox}>
            <Ionicons name="alert-circle" size={20} color={colors.status.warning} />
            <Text style={styles.warningText}>{attomError}</Text>
          </View>
        )}

        {/* Property Card */}
        <Card style={styles.propertyCard}>
          <View style={styles.addressHeader}>
            <Ionicons name="home" size={24} color={colors.haven.navy[900]} />
            <View style={styles.addressText}>
              <Text style={styles.addressLine}>{editedData.addressLine1}</Text>
              <Text style={styles.cityState}>
                {editedData.city}, {editedData.state} {editedData.postalCode}
              </Text>
            </View>
            <Badge label="Verified" variant="success" />
          </View>
        </Card>

        {/* Property Details */}
        <Card style={styles.detailsCard}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Property Details</Text>
            <TouchableOpacity onPress={() => setIsEditing(!isEditing)}>
              <Text style={styles.editButton}>
                {isEditing ? 'Done' : 'Edit'}
              </Text>
            </TouchableOpacity>
          </View>

          {isEditing ? (
            <View style={styles.editForm}>
              <Input
                label="Year Built"
                value={editedData.yearBuilt?.toString() || ''}
                onChangeText={(v) => setEditedData({ ...editedData, yearBuilt: parseInt(v) || undefined })}
                keyboardType="number-pad"
              />
              <Input
                label="Square Feet"
                value={editedData.squareFeet?.toString() || ''}
                onChangeText={(v) => setEditedData({ ...editedData, squareFeet: parseInt(v) || undefined })}
                keyboardType="number-pad"
              />
              <View style={styles.row}>
                <Input
                  label="Bedrooms"
                  value={editedData.bedrooms?.toString() || ''}
                  onChangeText={(v) => setEditedData({ ...editedData, bedrooms: parseInt(v) || undefined })}
                  keyboardType="number-pad"
                  containerStyle={{ flex: 1 }}
                />
                <Input
                  label="Bathrooms"
                  value={editedData.bathrooms?.toString() || ''}
                  onChangeText={(v) => setEditedData({ ...editedData, bathrooms: parseFloat(v) || undefined })}
                  keyboardType="decimal-pad"
                  containerStyle={{ flex: 1 }}
                />
              </View>
            </View>
          ) : (
            <View style={styles.detailsGrid}>
              <DetailItem label="Type" value={editedData.propertyType?.replace('_', ' ')} />
              <DetailItem label="Year Built" value={formatValue(editedData.yearBuilt)} />
              <DetailItem label="Square Feet" value={formatValue(editedData.squareFeet, ' sqft')} />
              <DetailItem label="Bedrooms" value={formatValue(editedData.bedrooms)} />
              <DetailItem label="Bathrooms" value={formatValue(editedData.bathrooms)} />
              <DetailItem label="Lot Size" value={formatValue(editedData.lotSize, ' acres')} />
            </View>
          )}
        </Card>

        {/* Systems & Features */}
        <Card style={styles.detailsCard}>
          <Text style={styles.sectionTitle}>Systems & Features</Text>
          <View style={styles.detailsGrid}>
            <DetailItem label="HVAC" value={formatValue(editedData.hvacType)} />
            <DetailItem label="Heating" value={formatValue(editedData.heatingFuel)} />
            <DetailItem label="Pool" value={editedData.hasPool ? 'Yes' : 'No'} />
            <DetailItem label="Fireplace" value={editedData.hasFireplace ? 'Yes' : 'No'} />
            <DetailItem label="Roof" value={formatValue(editedData.roofType)} />
          </View>
        </Card>

        {/* Utilities */}
        {(editedData.electricProvider || editedData.gasProvider || editedData.waterProvider) && (
          <Card style={styles.detailsCard}>
            <Text style={styles.sectionTitle}>Local Utilities</Text>
            <View style={styles.detailsGrid}>
              {editedData.electricProvider && (
                <DetailItem
                  label="Electric"
                  value={editedData.electricProvider}
                  icon="flash-outline"
                />
              )}
              {editedData.gasProvider && (
                <DetailItem
                  label="Gas"
                  value={editedData.gasProvider}
                  icon="flame-outline"
                />
              )}
              {editedData.waterProvider && (
                <DetailItem
                  label="Water"
                  value={editedData.waterProvider}
                  icon="water-outline"
                />
              )}
            </View>
          </Card>
        )}

        {/* Continue Button */}
        <Button
          title={isLoading ? 'Saving...' : 'Looks Good!'}
          onPress={handleSave}
          loading={isLoading}
          fullWidth
          style={styles.continueButton}
        />

        <Button
          title="Go Back"
          onPress={() => router.back()}
          variant="ghost"
          fullWidth
        />
      </ScrollView>
    </SafeAreaView>
  );
}

// Detail item component
function DetailItem({
  label,
  value,
  icon,
}: {
  label: string;
  value: string;
  icon?: string;
}) {
  const isDetected = value !== 'Not detected';

  return (
    <View style={detailStyles.item}>
      {icon && (
        <Ionicons
          name={icon as any}
          size={16}
          color={colors.haven.champagne[500]}
          style={detailStyles.icon}
        />
      )}
      <Text style={detailStyles.label}>{label}</Text>
      <Text style={[detailStyles.value, !isDetected && detailStyles.notDetected]}>
        {value}
      </Text>
    </View>
  );
}

const detailStyles = StyleSheet.create({
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  icon: {
    marginRight: spacing[2],
  },
  label: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  value: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  notDetected: {
    color: colors.text.tertiary,
    fontStyle: 'italic',
  },
});

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[5],
    paddingBottom: spacing[8],
  },
  progress: {
    marginBottom: spacing[4],
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
    marginBottom: spacing[4],
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
  },
  warningBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.status.warningLight,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
    gap: spacing[2],
  },
  warningText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.status.warning,
  },
  propertyCard: {
    marginBottom: spacing[4],
    padding: spacing[4],
  },
  addressHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  addressText: {
    flex: 1,
    marginLeft: spacing[3],
  },
  addressLine: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  cityState: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  detailsCard: {
    marginBottom: spacing[4],
    padding: spacing[4],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  editButton: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[500],
    fontWeight: typography.fontWeights.medium,
  },
  detailsGrid: {},
  editForm: {},
  row: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  continueButton: {
    marginTop: spacing[2],
    marginBottom: spacing[3],
  },
});
```

### Task 3.4: Update Onboarding Context

Update `apps/mobile/src/contexts/onboarding-context.tsx` to support the new data structure:

```typescript
import React, { createContext, useContext, useState, ReactNode } from 'react';
import { PropertyData, OnboardingState } from '../types/onboarding';

interface OnboardingContextType extends OnboardingState {
  setStep: (step: OnboardingState['step']) => void;
  setPropertyData: (data: PropertyData | null) => void;
  setHouseholdId: (id: string | null) => void;
  setIsLoadingAttom: (loading: boolean) => void;
  setAttomError: (error: string | null) => void;
  reset: () => void;
}

const initialState: OnboardingState = {
  step: 'address',
  propertyData: null,
  householdId: null,
  isLoadingAttom: false,
  attomError: null,
};

const OnboardingContext = createContext<OnboardingContextType | null>(null);

export function OnboardingProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<OnboardingState>(initialState);

  const setStep = (step: OnboardingState['step']) => {
    setState(prev => ({ ...prev, step }));
  };

  const setPropertyData = (data: PropertyData | null) => {
    setState(prev => ({ ...prev, propertyData: data }));
  };

  const setHouseholdId = (id: string | null) => {
    setState(prev => ({ ...prev, householdId: id }));
  };

  const setIsLoadingAttom = (loading: boolean) => {
    setState(prev => ({ ...prev, isLoadingAttom: loading }));
  };

  const setAttomError = (error: string | null) => {
    setState(prev => ({ ...prev, attomError: error }));
  };

  const reset = () => {
    setState(initialState);
  };

  return (
    <OnboardingContext.Provider
      value={{
        ...state,
        setStep,
        setPropertyData,
        setHouseholdId,
        setIsLoadingAttom,
        setAttomError,
        reset,
      }}
    >
      {children}
    </OnboardingContext.Provider>
  );
}

export function useOnboarding() {
  const context = useContext(OnboardingContext);
  if (!context) {
    throw new Error('useOnboarding must be used within OnboardingProvider');
  }
  return context;
}
```

### Task 3.5: Update Component Exports

Update `apps/mobile/src/components/index.ts`:

```typescript
// UI Components
export * from './ui/Button';
export * from './ui/Card';
export * from './ui/Badge';
export * from './ui/LoadingSpinner';

// Form Components
export * from './forms/Input';
export * from './forms/AddressAutocomplete';
```

---

## PHASE 4: Update Navigation

### Task 4.1: Update Onboarding Layout

Update `apps/mobile/app/(auth)/onboarding/_layout.tsx`:

```typescript
import { Stack } from 'expo-router';
import { colors, typography } from '../../../src/lib/theme';

export default function OnboardingLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: {
          backgroundColor: colors.background.secondary,
        },
        headerTintColor: colors.haven.navy[900],
        headerTitleStyle: {
          fontWeight: typography.fontWeights.semibold,
        },
        headerShadowVisible: false,
        headerBackTitleVisible: false,
        contentStyle: {
          backgroundColor: colors.background.secondary,
        },
      }}
    >
      <Stack.Screen
        name="address"
        options={{
          title: 'Your Home',
          headerBackVisible: false,
        }}
      />
      <Stack.Screen
        name="property"
        options={{
          title: 'Property Details',
        }}
      />
      <Stack.Screen
        name="bank"
        options={{
          title: 'Connect Bank',
        }}
      />
      <Stack.Screen
        name="plan"
        options={{
          title: 'Choose Plan',
        }}
      />
      <Stack.Screen
        name="complete"
        options={{
          headerShown: false,
        }}
      />
    </Stack>
  );
}
```

---

## PHASE 5: Verification

### Task 5.1: Test Checklist

- [ ] Address autocomplete shows predictions
- [ ] Selecting address triggers ATTOM lookup
- [ ] Property details display correctly
- [ ] Edit mode allows changing values
- [ ] Data saves correctly to backend
- [ ] Navigation flow works: address → property → bank
- [ ] Error states display properly
- [ ] Loading states show during API calls

### Task 5.2: Test Commands

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
pnpm typecheck
pnpm start --ios
```

---

## Summary

After completing this prompt:
1. ✅ Google Places address autocomplete
2. ✅ ATTOM property data integration
3. ✅ Auto-populated property details
4. ✅ Editable confirmation screen
5. ✅ Progress indicator through wizard
6. ✅ Error handling for failed lookups

**Next Prompt:** M04 - Plaid Integration for bill detection
