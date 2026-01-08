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

export interface AddressDetails {
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
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

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
