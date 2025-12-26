'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import { MapPin, Loader2, Check } from 'lucide-react';
import { cn } from '@/lib/utils';

interface AddressComponents {
  street: string;
  unit?: string;
  city: string;
  state: string;
  zipCode: string;
  country: string;
  formatted: string;
  latitude?: number;
  longitude?: number;
}

interface AddressAutocompleteProps {
  onAddressSelect: (address: AddressComponents) => void;
  defaultValue?: string;
  error?: string;
  placeholder?: string;
}

declare global {
  interface Window {
    google?: typeof google;
  }
}

export function AddressAutocomplete({
  onAddressSelect,
  defaultValue = '',
  error,
  placeholder = 'Start typing your address...',
}: AddressAutocompleteProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const autocompleteRef = useRef<google.maps.places.Autocomplete | null>(null);
  const [inputValue, setInputValue] = useState(defaultValue);
  const [isLoading, setIsLoading] = useState(false);
  const [isSelected, setIsSelected] = useState(!!defaultValue);
  const [isGoogleLoaded, setIsGoogleLoaded] = useState(false);

  // Load Google Maps script and check if it's ready
  useEffect(() => {
    const checkGoogle = () => {
      if (typeof window !== 'undefined' && window.google?.maps?.places) {
        setIsGoogleLoaded(true);
        return true;
      }
      return false;
    };

    // If already loaded, we're done
    if (checkGoogle()) {
      return;
    }

    // Check if script is already being loaded
    const existingScript = document.querySelector('script[src*="maps.googleapis.com"]');
    if (existingScript) {
      // Wait for existing script to load
      const interval = setInterval(() => {
        if (checkGoogle()) {
          clearInterval(interval);
        }
      }, 100);
      return () => clearInterval(interval);
    }

    // Load the Google Maps script
    const apiKey = process.env.NEXT_PUBLIC_GOOGLE_PLACES_API_KEY;
    if (!apiKey) {
      console.error('Google Places API key not configured');
      return;
    }

    const script = document.createElement('script');
    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=places`;
    script.async = true;
    script.defer = true;
    script.onload = () => {
      // Poll until places library is ready
      const interval = setInterval(() => {
        if (checkGoogle()) {
          clearInterval(interval);
        }
      }, 50);
    };
    script.onerror = () => {
      console.error('Failed to load Google Maps script');
    };
    document.head.appendChild(script);

    return () => {
      // Don't remove script as other components may use it
    };
  }, []);

  // Parse Google Place result into our format
  const parsePlace = useCallback((place: google.maps.places.PlaceResult): AddressComponents | null => {
    if (!place.address_components) return null;

    const getComponent = (type: string): string => {
      const component = place.address_components?.find(c => c.types.includes(type));
      return component?.long_name || '';
    };

    const getComponentShort = (type: string): string => {
      const component = place.address_components?.find(c => c.types.includes(type));
      return component?.short_name || '';
    };

    const streetNumber = getComponent('street_number');
    const route = getComponent('route');
    const street = streetNumber ? `${streetNumber} ${route}` : route;

    return {
      street,
      city: getComponent('locality') || getComponent('sublocality') || getComponent('administrative_area_level_3'),
      state: getComponentShort('administrative_area_level_1'),
      zipCode: getComponent('postal_code'),
      country: getComponentShort('country'),
      formatted: place.formatted_address || '',
      latitude: place.geometry?.location?.lat(),
      longitude: place.geometry?.location?.lng(),
    };
  }, []);

  // Initialize autocomplete when Google Maps is loaded
  useEffect(() => {
    if (!inputRef.current || !isGoogleLoaded) return;

    // Create autocomplete instance
    autocompleteRef.current = new google.maps.places.Autocomplete(inputRef.current, {
      componentRestrictions: { country: 'us' },
      fields: ['address_components', 'formatted_address', 'geometry'],
      types: ['address'],
    });

    // Handle place selection
    autocompleteRef.current.addListener('place_changed', () => {
      const place = autocompleteRef.current?.getPlace();
      if (place) {
        setIsLoading(true);
        const parsed = parsePlace(place);
        if (parsed) {
          setInputValue(parsed.formatted);
          setIsSelected(true);
          onAddressSelect(parsed);
        }
        setIsLoading(false);
      }
    });

    return () => {
      if (autocompleteRef.current) {
        google.maps.event.clearInstanceListeners(autocompleteRef.current);
      }
    };
  }, [isGoogleLoaded, onAddressSelect, parsePlace]);

  // Handle manual input changes
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value);
    setIsSelected(false);
  };

  return (
    <div className="space-y-1">
      <label className="block text-sm font-medium text-gray-700">
        Property Address <span className="text-red-500">*</span>
      </label>
      <div className="relative">
        <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
          {isLoading ? (
            <Loader2 className="w-5 h-5 animate-spin" />
          ) : isSelected ? (
            <Check className="w-5 h-5 text-green-500" />
          ) : (
            <MapPin className="w-5 h-5" />
          )}
        </div>
        <input
          ref={inputRef}
          type="text"
          value={inputValue}
          onChange={handleInputChange}
          placeholder={placeholder}
          className={cn(
            'w-full pl-11 pr-4 py-3 rounded-xl border transition-all outline-none',
            'focus:ring-2 focus:ring-haven-champagne-200',
            error
              ? 'border-red-300 focus:border-red-500'
              : isSelected
                ? 'border-green-300 focus:border-green-500'
                : 'border-gray-300 focus:border-haven-champagne-500'
          )}
        />
      </div>
      {error && (
        <p className="text-sm text-red-600">{error}</p>
      )}
      {!isGoogleLoaded && (
        <p className="text-xs text-gray-400">
          Loading address autocomplete...
        </p>
      )}
      {isGoogleLoaded && !isSelected && (
        <p className="text-xs text-gray-400">
          Start typing and select your address from the dropdown
        </p>
      )}
    </div>
  );
}
