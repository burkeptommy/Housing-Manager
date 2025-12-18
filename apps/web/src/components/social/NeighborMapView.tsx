'use client';

import { useState, useCallback, useEffect } from 'react';
import Map, { Marker, Popup, NavigationControl } from 'react-map-gl';
import 'mapbox-gl/dist/mapbox-gl.css';

const MAPBOX_TOKEN = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;

// Map pin data from API
export interface MapPin {
  id: string;
  title: string;
  h3Index: string;
  costDisplay: string | null;
  actualCost: number | null;
  vendor: {
    id: string;
    displayName: string;
    category?: string;
  } | null;
  isVerified: boolean;
  createdAt: string;
  // For display, we need to geocode from h3Index to lat/lng
  // In a real app, this would come from the API
  latitude?: number;
  longitude?: number;
}

interface NeighborMapViewProps {
  pins: MapPin[];
  centerLat?: number;
  centerLng?: number;
  onPinClick?: (pin: MapPin) => void;
}

// Format cost for display
function formatCost(pin: MapPin): string | null {
  if (!pin.costDisplay || pin.costDisplay === 'HIDDEN') return null;
  if (pin.costDisplay === 'EXACT' && pin.actualCost) {
    return `$${pin.actualCost.toLocaleString()}`;
  }
  // For range, we just show a category indicator
  return '$';
}

// Pin marker component
function PinMarker({ isSelected }: { isSelected: boolean }) {
  return (
    <div
      className={`w-8 h-8 rounded-full flex items-center justify-center shadow-lg cursor-pointer transform transition-transform ${
        isSelected ? 'scale-125' : 'hover:scale-110'
      } ${isSelected ? 'bg-emerald-600' : 'bg-white dark:bg-slate-800'}`}
    >
      <span className={`text-sm ${isSelected ? 'text-white' : ''}`}>🏠</span>
    </div>
  );
}

export function NeighborMapView({
  pins,
  centerLat = 37.7749, // Default to SF
  centerLng = -122.4194,
  onPinClick,
}: NeighborMapViewProps) {
  const [selectedPin, setSelectedPin] = useState<MapPin | null>(null);
  const [viewState, setViewState] = useState({
    latitude: centerLat,
    longitude: centerLng,
    zoom: 13,
  });

  // Update center when props change
  useEffect(() => {
    setViewState((prev) => ({
      ...prev,
      latitude: centerLat,
      longitude: centerLng,
    }));
  }, [centerLat, centerLng]);

  const handleMarkerClick = useCallback(
    (pin: MapPin) => {
      setSelectedPin(pin);
      onPinClick?.(pin);
    },
    [onPinClick]
  );

  if (!MAPBOX_TOKEN) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-slate-100 dark:bg-slate-800 rounded-xl">
        <div className="text-center text-slate-500 dark:text-slate-400">
          <div className="text-4xl mb-2">🗺️</div>
          <p>Map not configured</p>
          <p className="text-sm">Missing NEXT_PUBLIC_MAPBOX_TOKEN</p>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full h-full rounded-xl overflow-hidden">
      <Map
        {...viewState}
        onMove={(evt) => setViewState(evt.viewState)}
        mapStyle="mapbox://styles/mapbox/light-v11"
        mapboxAccessToken={MAPBOX_TOKEN}
        style={{ width: '100%', height: '100%' }}
      >
        <NavigationControl position="top-right" />

        {pins.map((pin) => {
          // Skip pins without coordinates
          if (!pin.latitude || !pin.longitude) return null;

          return (
            <Marker
              key={pin.id}
              latitude={pin.latitude}
              longitude={pin.longitude}
              anchor="bottom"
              onClick={(e) => {
                e.originalEvent.stopPropagation();
                handleMarkerClick(pin);
              }}
            >
              <PinMarker isSelected={selectedPin?.id === pin.id} />
            </Marker>
          );
        })}

        {selectedPin && selectedPin.latitude && selectedPin.longitude && (
          <Popup
            latitude={selectedPin.latitude}
            longitude={selectedPin.longitude}
            anchor="bottom"
            offset={25}
            onClose={() => setSelectedPin(null)}
            closeButton={true}
            closeOnClick={false}
          >
            <div className="p-2 min-w-[200px]">
              <div className="flex items-center gap-2 mb-2">
                <h3 className="font-semibold text-slate-900 dark:text-white text-sm">
                  {selectedPin.title}
                </h3>
                {selectedPin.isVerified && (
                  <span className="text-xs bg-green-100 text-green-700 px-1.5 py-0.5 rounded flex items-center gap-0.5">
                    <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                    Verified
                  </span>
                )}
              </div>

              <p className="text-xs text-slate-500 dark:text-slate-400 mb-2">
                A neighbor nearby
              </p>

              {selectedPin.vendor && (
                <div className="text-xs text-slate-600 dark:text-slate-300 mb-1">
                  <span className="font-medium">{selectedPin.vendor.displayName}</span>
                  {selectedPin.vendor.category && (
                    <span className="text-slate-400"> • {selectedPin.vendor.category}</span>
                  )}
                </div>
              )}

              {formatCost(selectedPin) && (
                <div className="text-sm font-medium text-green-600 dark:text-green-400">
                  {formatCost(selectedPin)}
                </div>
              )}

              <button
                onClick={() => onPinClick?.(selectedPin)}
                className="mt-2 w-full text-xs text-emerald-600 dark:text-emerald-400 hover:underline"
              >
                View Details →
              </button>
            </div>
          </Popup>
        )}
      </Map>
    </div>
  );
}

export default NeighborMapView;
