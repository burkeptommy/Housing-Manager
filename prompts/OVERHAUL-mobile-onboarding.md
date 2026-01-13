# Haven Mobile - Complete Onboarding Overhaul

## OVERVIEW

Rebuild the mobile registration/onboarding flow to match web functionality:
1. Fix old logo usage (use actual Haven icon)
2. Social auth (Apple/Google) should go directly to address entry, not registration form
3. Add Google Places autocomplete for address entry
4. Add ATTOM property confirmation step
5. Simplify flow: Auth → Address → Confirm Property → Done

---

## CURRENT PROBLEMS

1. **Old Logo**: Register screen shows "H" in a box instead of actual Haven logo
2. **Social Auth Flow**: Apple/Google sign-in for new users shows registration form instead of going to onboarding
3. **No Address Autocomplete**: Mobile doesn't have Google Places dropdown like web
4. **No ATTOM Confirmation**: Missing the "Does this look right?" step showing bedrooms, bathrooms, heating type, etc.
5. **Flow is confusing**: Too many steps, not enough auto-population

---

## NEW FLOW DESIGN

### Flow A: Email Registration
```
1. Register Screen (email/password/name)
   ↓
2. Address Entry (with Google Places autocomplete)
   ↓
3. Property Confirmation (ATTOM data: beds, baths, heating, etc.)
   ↓
4. Done → Main App
```

### Flow B: Social Auth (Apple/Google)
```
1. Login Screen → Tap Apple/Google
   ↓
2. [If new user] Address Entry (with Google Places autocomplete)
   - Pre-fill name from social auth
   ↓
3. Property Confirmation (ATTOM data)
   ↓
4. Done → Main App
```

---

## IMPLEMENTATION

### STEP 1: Fix Logo on Register Screen

**File:** `apps/mobile/app/(auth)/register.tsx`

Replace the "H" logo with the actual Haven icon:

```typescript
import { Image } from 'react-native';

// In the header section, replace:
<View style={styles.logo}>
  <Text style={styles.logoText}>H</Text>
</View>

// With:
<Image
  source={require('../../assets/icon.png')}
  style={styles.logo}
  resizeMode="contain"
/>

// Update styles:
logo: {
  width: 72,
  height: 72,
  borderRadius: 16,
},
// Remove logoText style
```

### STEP 2: Create Dedicated Onboarding Screens

Create a new onboarding folder: `apps/mobile/app/(onboarding)/`

**File Structure:**
```
apps/mobile/app/
├── (onboarding)/
│   ├── _layout.tsx
│   ├── address.tsx        # Step 1: Address with Google Places
│   ├── confirm-property.tsx  # Step 2: ATTOM confirmation
│   └── complete.tsx       # Final success screen
```

### STEP 3: Create Address Autocomplete Component

**File:** `apps/mobile/src/components/AddressAutocomplete.tsx`

```typescript
import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, typography, borderRadius } from '../lib/theme';

const GOOGLE_PLACES_API_KEY = process.env.EXPO_PUBLIC_GOOGLE_PLACES_API_KEY;

interface AddressPrediction {
  place_id: string;
  description: string;
  structured_formatting: {
    main_text: string;
    secondary_text: string;
  };
}

interface ParsedAddress {
  street: string;
  city: string;
  state: string;
  zipCode: string;
  formatted: string;
  latitude?: number;
  longitude?: number;
}

interface AddressAutocompleteProps {
  onAddressSelect: (address: ParsedAddress) => void;
  defaultValue?: string;
  error?: string;
  placeholder?: string;
}

export function AddressAutocomplete({
  onAddressSelect,
  defaultValue = '',
  error,
  placeholder = 'Start typing your address...',
}: AddressAutocompleteProps) {
  const [query, setQuery] = useState(defaultValue);
  const [predictions, setPredictions] = useState<AddressPrediction[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);
  const [isSelected, setIsSelected] = useState(false);
  const debounceRef = useRef<NodeJS.Timeout>();

  // Fetch predictions from Google Places API
  const fetchPredictions = async (input: string) => {
    if (!input || input.length < 3 || !GOOGLE_PLACES_API_KEY) {
      setPredictions([]);
      return;
    }

    setIsLoading(true);
    try {
      const response = await fetch(
        `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&types=address&components=country:us&key=${GOOGLE_PLACES_API_KEY}`
      );
      const data = await response.json();
      
      if (data.predictions) {
        setPredictions(data.predictions);
        setShowDropdown(true);
      }
    } catch (err) {
      console.error('Places autocomplete error:', err);
    } finally {
      setIsLoading(false);
    }
  };

  // Fetch place details to get full address components
  const fetchPlaceDetails = async (placeId: string): Promise<ParsedAddress | null> => {
    if (!GOOGLE_PLACES_API_KEY) return null;

    try {
      const response = await fetch(
        `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=address_components,formatted_address,geometry&key=${GOOGLE_PLACES_API_KEY}`
      );
      const data = await response.json();
      
      if (data.result) {
        const components = data.result.address_components || [];
        
        const getComponent = (type: string): string => {
          const comp = components.find((c: any) => c.types.includes(type));
          return comp?.long_name || '';
        };
        
        const getShortComponent = (type: string): string => {
          const comp = components.find((c: any) => c.types.includes(type));
          return comp?.short_name || '';
        };

        const streetNumber = getComponent('street_number');
        const route = getComponent('route');
        
        return {
          street: streetNumber ? `${streetNumber} ${route}` : route,
          city: getComponent('locality') || getComponent('sublocality') || getComponent('administrative_area_level_3'),
          state: getShortComponent('administrative_area_level_1'),
          zipCode: getComponent('postal_code'),
          formatted: data.result.formatted_address,
          latitude: data.result.geometry?.location?.lat,
          longitude: data.result.geometry?.location?.lng,
        };
      }
    } catch (err) {
      console.error('Place details error:', err);
    }
    return null;
  };

  // Debounced search
  useEffect(() => {
    if (debounceRef.current) {
      clearTimeout(debounceRef.current);
    }

    if (!isSelected && query.length >= 3) {
      debounceRef.current = setTimeout(() => {
        fetchPredictions(query);
      }, 300);
    } else {
      setPredictions([]);
      setShowDropdown(false);
    }

    return () => {
      if (debounceRef.current) {
        clearTimeout(debounceRef.current);
      }
    };
  }, [query, isSelected]);

  // Handle prediction selection
  const handleSelect = async (prediction: AddressPrediction) => {
    setIsLoading(true);
    setShowDropdown(false);
    setQuery(prediction.description);
    setIsSelected(true);

    const details = await fetchPlaceDetails(prediction.place_id);
    if (details) {
      onAddressSelect(details);
    }
    setIsLoading(false);
  };

  // Handle text change
  const handleTextChange = (text: string) => {
    setQuery(text);
    setIsSelected(false);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.label}>Property Address</Text>
      <View style={styles.inputContainer}>
        <View style={styles.iconContainer}>
          {isLoading ? (
            <ActivityIndicator size="small" color={colors.haven.champagne[500]} />
          ) : isSelected ? (
            <Ionicons name="checkmark-circle" size={20} color="#10b981" />
          ) : (
            <Ionicons name="location-outline" size={20} color={colors.haven.navy[400]} />
          )}
        </View>
        <TextInput
          style={[
            styles.input,
            isSelected && styles.inputSelected,
            error && styles.inputError,
          ]}
          value={query}
          onChangeText={handleTextChange}
          placeholder={placeholder}
          placeholderTextColor={colors.haven.navy[400]}
          autoCorrect={false}
        />
      </View>

      {/* Predictions Dropdown */}
      {showDropdown && predictions.length > 0 && (
        <View style={styles.dropdown}>
          <FlatList
            data={predictions}
            keyExtractor={(item) => item.place_id}
            keyboardShouldPersistTaps="handled"
            renderItem={({ item }) => (
              <TouchableOpacity
                style={styles.predictionItem}
                onPress={() => handleSelect(item)}
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
          />
        </View>
      )}

      {error && <Text style={styles.errorText}>{error}</Text>}
      
      {!isSelected && !error && (
        <Text style={styles.hint}>
          Start typing and select your address from the dropdown
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[700],
    marginBottom: spacing[2],
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconContainer: {
    position: 'absolute',
    left: spacing[3],
    zIndex: 1,
  },
  input: {
    flex: 1,
    backgroundColor: colors.haven.navy[50],
    borderWidth: 1,
    borderColor: colors.haven.navy[200],
    borderRadius: borderRadius.lg,
    paddingVertical: spacing[4],
    paddingLeft: spacing[10],
    paddingRight: spacing[4],
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[900],
  },
  inputSelected: {
    borderColor: '#10b981',
    backgroundColor: '#f0fdf4',
  },
  inputError: {
    borderColor: colors.status.error,
  },
  dropdown: {
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.haven.navy[200],
    borderRadius: borderRadius.lg,
    marginTop: spacing[2],
    maxHeight: 250,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  predictionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.haven.navy[100],
  },
  predictionIcon: {
    marginRight: spacing[3],
  },
  predictionText: {
    flex: 1,
  },
  predictionMain: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[900],
  },
  predictionSecondary: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    marginTop: 2,
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.status.error,
    marginTop: spacing[1],
  },
  hint: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.navy[400],
    marginTop: spacing[1],
  },
});
```

### STEP 4: Create Onboarding Layout

**File:** `apps/mobile/app/(onboarding)/_layout.tsx`

```typescript
import { Stack } from 'expo-router';
import { colors } from '../../src/lib/theme';

export default function OnboardingLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: colors.haven.navy[50] },
        animation: 'slide_from_right',
      }}
    >
      <Stack.Screen name="address" />
      <Stack.Screen name="confirm-property" />
      <Stack.Screen name="complete" />
    </Stack>
  );
}
```

### STEP 5: Create Address Entry Screen

**File:** `apps/mobile/app/(onboarding)/address.tsx`

```typescript
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
import { AddressAutocomplete } from '../../src/components/AddressAutocomplete';
import { useAuth } from '../../src/contexts/auth-context';
import { colors, spacing, typography, borderRadius } from '../../src/lib/theme';

interface ParsedAddress {
  street: string;
  city: string;
  state: string;
  zipCode: string;
  formatted: string;
  latitude?: number;
  longitude?: number;
}

export default function AddressScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();
  const { pendingSocialAuth } = useAuth();
  
  // Get name from social auth or params
  const firstName = pendingSocialAuth?.firstName || (params.firstName as string) || '';
  const lastName = pendingSocialAuth?.lastName || (params.lastName as string) || '';
  const email = pendingSocialAuth?.email || (params.email as string) || '';
  
  const [selectedAddress, setSelectedAddress] = useState<ParsedAddress | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAddressSelect = (address: ParsedAddress) => {
    setSelectedAddress(address);
    setError(null);
  };

  const handleContinue = async () => {
    if (!selectedAddress) {
      setError('Please select your address from the dropdown');
      return;
    }

    setIsLoading(true);

    // Navigate to property confirmation with address data
    router.push({
      pathname: '/(onboarding)/confirm-property',
      params: {
        street: selectedAddress.street,
        city: selectedAddress.city,
        state: selectedAddress.state,
        zipCode: selectedAddress.zipCode,
        formatted: selectedAddress.formatted,
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
                {selectedAddress.formatted}
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
        <Text style={styles.privacyNote}>
          <Ionicons name="lock-closed" size={12} color={colors.haven.navy[400]} />
          {' '}Your information is secure and never shared.
        </Text>
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
  privacyNote: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.navy[400],
    textAlign: 'center',
    marginTop: spacing[6],
  },
});
```

### STEP 6: Create Property Confirmation Screen (ATTOM Data)

**File:** `apps/mobile/app/(onboarding)/confirm-property.tsx`

```typescript
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
  const { completeSocialRegistration, registerSimple, pendingSocialAuth } = useAuth();

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

  // Fetch property details from ATTOM via API
  useEffect(() => {
    fetchPropertyDetails();
  }, []);

  const fetchPropertyDetails = async () => {
    setIsLoading(true);
    try {
      const token = await getIdToken();
      const apiUrl = process.env.EXPO_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const queryParams = new URLSearchParams({
        street,
        city,
        state,
        zip: zipCode,
      });

      const response = await fetch(`${apiUrl}/property/lookup?${queryParams}`, {
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
      // Not a fatal error - we can proceed without ATTOM data
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

      let result;

      // If we have pending social auth, complete that registration
      if (pendingSocialAuth) {
        result = await completeSocialRegistration({
          email: pendingSocialAuth.email || email,
          firstName: firstName || pendingSocialAuth.firstName,
          lastName: lastName || pendingSocialAuth.lastName,
          address: addressData,
          propertyDetails, // Pass ATTOM data to backend
        });
      } else {
        // Regular registration (email/password was already done)
        // This shouldn't happen in normal flow, but handle it
        Alert.alert('Error', 'Please start registration again');
        router.replace('/(auth)/register');
        return;
      }

      if (result.success) {
        // Navigate to completion or main app
        router.replace('/(onboarding)/complete');
      } else {
        setError(result.error || 'Failed to complete registration');
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
    value 
  }: { 
    icon: string; 
    label: string; 
    value: string | number | null;
  }) => (
    <View style={styles.propertyRow}>
      <View style={styles.propertyIcon}>
        <Ionicons name={icon as any} size={20} color={colors.haven.champagne[500]} />
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
          <Ionicons name="home" size={24} color={colors.haven.champagne[500]} />
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
              <ActivityIndicator size="large" color={colors.haven.champagne[500]} />
              <Text style={styles.loadingText}>Looking up property details...</Text>
            </View>
          ) : propertyDetails ? (
            <>
              <View style={styles.autoFilledBadge}>
                <Ionicons name="sparkles" size={14} color={colors.haven.champagne[600]} />
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
              <Ionicons name="information-circle-outline" size={32} color={colors.haven.navy[400]} />
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
          disabled={isSubmitting}
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
          <Ionicons name="arrow-back" size={20} color={colors.haven.navy[600]} />
          <Text style={styles.backButtonText}>Change Address</Text>
        </TouchableOpacity>
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
    color: colors.haven.navy[900],
    marginBottom: spacing[2],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[500],
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
    color: colors.haven.navy[900],
  },
  addressCity: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    marginTop: 2,
  },
  editLink: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
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
    color: colors.haven.navy[500],
  },
  autoFilledBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.champagne[50],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    alignSelf: 'flex-start',
    marginBottom: spacing[4],
    gap: spacing[1],
  },
  autoFilledText: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.champagne[600],
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
    borderBottomColor: colors.haven.navy[100],
  },
  propertyIcon: {
    width: 32,
  },
  propertyLabel: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
  },
  propertyValue: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[900],
  },
  noDataContainer: {
    alignItems: 'center',
    paddingVertical: spacing[6],
  },
  noDataText: {
    marginTop: spacing[3],
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    textAlign: 'center',
    lineHeight: 20,
  },
  nextStepsCard: {
    backgroundColor: colors.haven.champagne[50],
    borderRadius: borderRadius.lg,
    padding: spacing[5],
    marginBottom: spacing[6],
  },
  nextStepsTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
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
    backgroundColor: colors.haven.champagne[500],
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
    color: colors.haven.navy[600],
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
    backgroundColor: colors.haven.navy[900],
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
    color: colors.haven.navy[600],
  },
});
```

### STEP 7: Create Completion Screen

**File:** `apps/mobile/app/(onboarding)/complete.tsx`

```typescript
import React, { useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Image,
  Animated,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, typography, borderRadius } from '../../src/lib/theme';

export default function CompleteScreen() {
  const router = useRouter();
  const fadeAnim = React.useRef(new Animated.Value(0)).current;
  const scaleAnim = React.useRef(new Animated.Value(0.8)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 600,
        useNativeDriver: true,
      }),
      Animated.spring(scaleAnim, {
        toValue: 1,
        friction: 8,
        tension: 40,
        useNativeDriver: true,
      }),
    ]).start();
  }, []);

  const handleGetStarted = () => {
    // Navigate to main app - auth context will handle the rest
    router.replace('/(tabs)');
  };

  return (
    <SafeAreaView style={styles.container}>
      <Animated.View 
        style={[
          styles.content,
          { opacity: fadeAnim, transform: [{ scale: scaleAnim }] }
        ]}
      >
        {/* Success Icon */}
        <View style={styles.iconContainer}>
          <View style={styles.iconCircle}>
            <Ionicons name="checkmark" size={48} color={colors.white} />
          </View>
        </View>

        {/* Header */}
        <Text style={styles.title}>You're all set!</Text>
        <Text style={styles.subtitle}>
          Welcome to Haven. Your home is now set up and ready to go.
        </Text>

        {/* What's Next Card */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>What's next?</Text>
          
          <View style={styles.featureRow}>
            <View style={styles.featureIcon}>
              <Ionicons name="chatbubble-ellipses" size={20} color={colors.haven.champagne[500]} />
            </View>
            <View style={styles.featureText}>
              <Text style={styles.featureTitle}>Meet Alfred</Text>
              <Text style={styles.featureDescription}>
                Your AI home manager will help complete your profile and answer questions
              </Text>
            </View>
          </View>

          <View style={styles.featureRow}>
            <View style={styles.featureIcon}>
              <Ionicons name="card" size={20} color={colors.haven.champagne[500]} />
            </View>
            <View style={styles.featureText}>
              <Text style={styles.featureTitle}>Connect Bills</Text>
              <Text style={styles.featureDescription}>
                Link your bank to auto-detect bills and set up consolidated payments
              </Text>
            </View>
          </View>

          <View style={styles.featureRow}>
            <View style={styles.featureIcon}>
              <Ionicons name="construct" size={20} color={colors.haven.champagne[500]} />
            </View>
            <View style={styles.featureText}>
              <Text style={styles.featureTitle}>Maintenance Reminders</Text>
              <Text style={styles.featureDescription}>
                We've created a maintenance schedule based on your home's systems
              </Text>
            </View>
          </View>
        </View>

        {/* Get Started Button */}
        <TouchableOpacity style={styles.button} onPress={handleGetStarted}>
          <Text style={styles.buttonText}>Get Started</Text>
          <Ionicons name="arrow-forward" size={20} color={colors.white} />
        </TouchableOpacity>
      </Animated.View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.haven.navy[50],
  },
  content: {
    flex: 1,
    padding: spacing[6],
    justifyContent: 'center',
  },
  iconContainer: {
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  iconCircle: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: '#10b981',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#10b981',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.3,
    shadowRadius: 16,
    elevation: 8,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.haven.navy[900],
    textAlign: 'center',
    marginBottom: spacing[2],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[500],
    textAlign: 'center',
    marginBottom: spacing[8],
    lineHeight: 24,
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    marginBottom: spacing[8],
  },
  cardTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
    marginBottom: spacing[4],
  },
  featureRow: {
    flexDirection: 'row',
    marginBottom: spacing[4],
    gap: spacing[3],
  },
  featureIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  featureText: {
    flex: 1,
  },
  featureTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
    marginBottom: 2,
  },
  featureDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
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
  },
  buttonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
});
```

### STEP 8: Update Auth Context for Social Auth → Onboarding Flow

**File:** `apps/mobile/src/contexts/auth-context.tsx`

Update the social auth handlers to navigate to onboarding instead of showing registration form:

```typescript
// When Apple/Google sign-in completes for a NEW user (no household),
// navigate directly to onboarding instead of setting pendingSocialAuth

const handleSocialAuthSuccess = async (
  firebaseUser: FirebaseUser,
  provider: 'apple' | 'google',
  displayName?: string
) => {
  // Check if user has a household
  const meData = await fetchMe();
  
  if (!meData?.household) {
    // NEW USER - Navigate to onboarding with their info
    const [firstName, lastName] = (displayName || '').split(' ');
    
    router.replace({
      pathname: '/(onboarding)/address',
      params: {
        firstName: firstName || '',
        lastName: lastName || '',
        email: firebaseUser.email || '',
        provider,
      },
    });
    return;
  }
  
  // Existing user with household - go to main app
  router.replace('/(tabs)');
};
```

### STEP 9: Update Root Layout for Onboarding Routes

**File:** `apps/mobile/app/_layout.tsx`

Ensure the onboarding routes are included:

```typescript
// In the root layout, ensure (onboarding) group is accessible
<Stack.Screen name="(onboarding)" options={{ headerShown: false }} />
```

---

## API ENDPOINT REQUIREMENT

Ensure the API has the property lookup endpoint:

**GET /api/property/lookup**
- Query params: `street`, `city`, `state`, `zip`
- Returns ATTOM property data
- Should work without authentication (for onboarding)

---

## VERIFICATION CHECKLIST

### Logo
- [ ] Register screen uses actual Haven icon (not "H" box)
- [ ] Address screen uses actual Haven icon
- [ ] Confirm property screen uses actual Haven icon

### Social Auth Flow
- [ ] Apple sign-in for new users → Address screen (not registration form)
- [ ] Google sign-in for new users → Address screen
- [ ] Name pre-filled from social auth
- [ ] Existing users → Main app directly

### Address Autocomplete
- [ ] Google Places suggestions appear as user types
- [ ] Dropdown shows formatted addresses
- [ ] Selecting address populates all fields
- [ ] Selected address shows green checkmark

### ATTOM Confirmation
- [ ] Property details fetched from ATTOM API
- [ ] Shows bedrooms, bathrooms, sqft, year built
- [ ] Shows heating type/fuel (critical for Alfred questions)
- [ ] Shows water source and sewer type
- [ ] "Auto-filled from public records" badge
- [ ] Loading state while fetching
- [ ] Graceful handling if no data found

### Overall Flow
- [ ] Flow is: Auth → Address → Confirm → Done
- [ ] Progress feels fast and automated
- [ ] User can go back to edit address
- [ ] Completion screen shows what's next

---

## TEST

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

Test flows:
1. Fresh Apple Sign-In → Should go to address screen
2. Fresh Google Sign-In → Should go to address screen  
3. Type address → Autocomplete dropdown appears
4. Select address → Confirm screen shows ATTOM data
5. Confirm → Completion screen → Main app
