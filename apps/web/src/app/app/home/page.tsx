'use client';

import { useState, useCallback, useRef } from 'react';
import Link from 'next/link';
import Map, { Source, Layer, NavigationControl } from 'react-map-gl/mapbox';
import type { MapRef } from 'react-map-gl/mapbox';
import 'mapbox-gl/dist/mapbox-gl.css';
import {
  Eye,
  EyeOff,
  Copy,
  Check,
  Wifi,
  Shield,
  Key,
  Trash2,
  Mailbox,
  ThermometerSun,
  Droplets,
  Zap,
  Wind,
  Sun,
  Car,
  FileText,
  ChevronDown,
  ChevronRight,
  AlertTriangle,
  CheckCircle2,
  ExternalLink,
  Phone,
  Wrench,
  Home,
  Palette,
  Layers,
  Lightbulb,
  Filter,
  Image,
  Satellite,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type TabId = 'systems' | 'spaces' | 'utilities' | 'vehicles' | 'documents';

interface VaultItem {
  id: string;
  label: string;
  value: string;
  icon: typeof Wifi;
  masked?: boolean;
}

interface SystemAsset {
  id: string;
  name: string;
  icon: typeof ThermometerSun;
  make: string;
  model: string;
  serialNumber: string;
  installDate: string;
  warrantyExpires: string;
  location?: string;
  notes?: string;
}

interface RoomData {
  id: string;
  name: string;
  paint: { name: string; brand: string; code: string; hex: string }[];
  flooring: { material: string; brand: string; sku: string };
  lighting: { type: string; bulb: string }[];
  filters?: { size: string; location: string }[];
}

interface UtilityProvider {
  id: string;
  type: string;
  icon: typeof Zap;
  provider: string;
  accountNumber: string;
  meterNumber?: string;
  supportPhone: string;
  managedByHaven: boolean;
}

interface VehicleData {
  id: string;
  year: number;
  make: string;
  model: string;
  color: string;
  vin: string;
  licensePlate: string;
  tireSizeFront: string;
  tireSizeRear: string;
  oilType: string;
  insuranceCarrier: string;
  insurancePolicy: string;
  registrationExpires: string;
  imageUrl?: string;
}

interface DocumentCategory {
  id: string;
  name: string;
  count: number;
  icon: typeof FileText;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const propertyData = {
  address: "1247 Beverly Drive",
  city: "Beverly Hills",
  state: "CA",
  yearBuilt: 2018,
  sqft: 4200,
  lotSize: "0.35 acres",
  zoning: "Res-A",
  imageUrl: "/home-hero.jpg",
  // Coordinates for the property (Beverly Hills area)
  coordinates: {
    longitude: -118.4065,
    latitude: 34.0696,
  },
  // GeoJSON polygon for property boundary (approximate lot shape)
  propertyLine: {
    type: 'Feature' as const,
    properties: {},
    geometry: {
      type: 'Polygon' as const,
      coordinates: [[
        [-118.40680, 34.06980],
        [-118.40620, 34.06980],
        [-118.40620, 34.06940],
        [-118.40680, 34.06940],
        [-118.40680, 34.06980],
      ]],
    },
  },
};

const vaultItems: VaultItem[] = [
  { id: 'wifi', label: 'WiFi Network', value: 'HomeNetwork_5G / Tr0ub4dor&3', icon: Wifi, masked: true },
  { id: 'alarm', label: 'Alarm Code', value: '4729', icon: Shield, masked: true },
  { id: 'safe', label: 'Safe Combination', value: '24-08-16', icon: Shield, masked: true },
  { id: 'gate', label: 'Gate Code', value: '#1247', icon: Key, masked: false },
  { id: 'garage', label: 'Garage Keypad', value: '7294', icon: Key, masked: true },
  { id: 'trash', label: 'Trash Day', value: 'Tuesday', icon: Trash2, masked: false },
  { id: 'mailbox', label: 'Mailbox #', value: '247', icon: Mailbox, masked: false },
];

const systemAssets: SystemAsset[] = [
  {
    id: 'hvac1',
    name: 'HVAC - Zone 1 (Main)',
    icon: ThermometerSun,
    make: 'Carrier',
    model: 'Infinity 24ANB136A003',
    serialNumber: 'CA2419X78432',
    installDate: '2021-06-15',
    warrantyExpires: '2031-06-15',
    location: 'Attic - East Side',
    notes: 'Replaced compressor in 2023',
  },
  {
    id: 'hvac2',
    name: 'HVAC - Zone 2 (Upstairs)',
    icon: ThermometerSun,
    make: 'Carrier',
    model: 'Infinity 24ANB136A003',
    serialNumber: 'CA2419X78433',
    installDate: '2021-06-15',
    warrantyExpires: '2031-06-15',
    location: 'Attic - West Side',
  },
  {
    id: 'waterheater',
    name: 'Water Heater',
    icon: Droplets,
    make: 'Rheem',
    model: 'Professional Prestige',
    serialNumber: 'RH2020455728',
    installDate: '2020-03-10',
    warrantyExpires: '2026-03-10',
    location: 'Garage',
  },
  {
    id: 'roof',
    name: 'Roof',
    icon: Home,
    make: 'GAF',
    model: 'Timberline HDZ',
    serialNumber: 'N/A',
    installDate: '2018-01-01',
    warrantyExpires: '2043-01-01',
    notes: 'Original to house - 25 year warranty',
  },
  {
    id: 'pool',
    name: 'Pool Pump & Heater',
    icon: Droplets,
    make: 'Pentair',
    model: 'IntelliFlo VSF',
    serialNumber: 'PEN2021889432',
    installDate: '2021-04-20',
    warrantyExpires: '2024-04-20',
    location: 'Pool Equipment Pad',
  },
  {
    id: 'solar',
    name: 'Solar Array',
    icon: Sun,
    make: 'Tesla',
    model: 'Solar Roof',
    serialNumber: 'TSL2022X99281',
    installDate: '2022-08-01',
    warrantyExpires: '2047-08-01',
    notes: '8.5 kW system - 25 year warranty',
  },
];

const roomsData: RoomData[] = [
  {
    id: 'kitchen',
    name: 'Kitchen',
    paint: [
      { name: 'Revere Pewter', brand: 'Benjamin Moore', code: 'HC-172', hex: '#b5a999' },
      { name: 'White Dove', brand: 'Benjamin Moore', code: 'OC-17', hex: '#f3efe6' },
    ],
    flooring: { material: 'Oak Wide Plank', brand: 'Mohawk', sku: 'MHK-12345-OAK' },
    lighting: [
      { type: 'Pendant (Island)', bulb: 'E26 LED 2700K' },
      { type: 'Recessed', bulb: 'BR30 Soft White' },
    ],
  },
  {
    id: 'master-bath',
    name: 'Master Bathroom',
    paint: [
      { name: 'Decorator\'s White', brand: 'Benjamin Moore', code: 'CC-20', hex: '#f5f3ef' },
    ],
    flooring: { material: 'Marble Tile', brand: 'MSI', sku: 'CAL-WHT-1224' },
    lighting: [
      { type: 'Vanity', bulb: 'G25 LED 3000K' },
      { type: 'Shower', bulb: 'MR16 LED Damp Rated' },
    ],
  },
  {
    id: 'living-room',
    name: 'Living Room',
    paint: [
      { name: 'Simply White', brand: 'Benjamin Moore', code: 'OC-117', hex: '#f7f5ef' },
      { name: 'Hale Navy', brand: 'Benjamin Moore', code: 'HC-154', hex: '#3c4a5e' },
    ],
    flooring: { material: 'Oak Wide Plank', brand: 'Mohawk', sku: 'MHK-12345-OAK' },
    lighting: [
      { type: 'Chandelier', bulb: 'E12 Candelabra 2700K' },
      { type: 'Recessed', bulb: 'BR30 Soft White' },
    ],
    filters: [{ size: '20x25x1', location: 'Return Vent - Hallway' }],
  },
  {
    id: 'master-bedroom',
    name: 'Master Bedroom',
    paint: [
      { name: 'Calm', brand: 'Sherwin-Williams', code: 'SW 6183', hex: '#c5c9c7' },
    ],
    flooring: { material: 'Carpet - Wool Blend', brand: 'Shaw', sku: 'SHW-WOOL-789' },
    lighting: [
      { type: 'Ceiling Fan', bulb: 'A19 LED 2700K' },
      { type: 'Bedside Lamps', bulb: 'A19 LED Dimmable' },
    ],
  },
];

const utilityProviders: UtilityProvider[] = [
  {
    id: 'electric',
    type: 'Electric',
    icon: Zap,
    provider: 'Southern California Edison',
    accountNumber: '3-XXX-XXX-4821',
    meterNumber: 'E-28492847',
    supportPhone: '(800) 655-4555',
    managedByHaven: true,
  },
  {
    id: 'gas',
    type: 'Gas',
    icon: Wind,
    provider: 'SoCalGas',
    accountNumber: '8-XXX-XXX-9912',
    meterNumber: 'G-99281742',
    supportPhone: '(877) 238-0092',
    managedByHaven: true,
  },
  {
    id: 'water',
    type: 'Water & Sewer',
    icon: Droplets,
    provider: 'Beverly Hills Water',
    accountNumber: '247-XXX-882',
    supportPhone: '(310) 285-2467',
    managedByHaven: true,
  },
  {
    id: 'internet',
    type: 'Internet',
    icon: Wifi,
    provider: 'AT&T Fiber',
    accountNumber: '9XX-XXX-XX21',
    supportPhone: '(800) 288-2020',
    managedByHaven: true,
  },
  {
    id: 'trash',
    type: 'Trash & Recycling',
    icon: Trash2,
    provider: 'Athens Services',
    accountNumber: 'ATH-12478',
    supportPhone: '(888) 336-6100',
    managedByHaven: true,
  },
];

const vehicles: VehicleData[] = [
  {
    id: 'car1',
    year: 2023,
    make: 'Tesla',
    model: 'Model X',
    color: 'Pearl White',
    vin: '5YJXCAE27LF123456',
    licensePlate: '8ABC123',
    tireSizeFront: '265/45R20',
    tireSizeRear: '275/45R20',
    oilType: 'N/A (Electric)',
    insuranceCarrier: 'State Farm',
    insurancePolicy: 'SF-12345678',
    registrationExpires: '2025-03-15',
  },
  {
    id: 'car2',
    year: 2022,
    make: 'BMW',
    model: 'X5',
    color: 'Carbon Black',
    vin: '5UXCR6C09N9K12345',
    licensePlate: '8XYZ789',
    tireSizeFront: '275/45R20',
    tireSizeRear: '305/40R20',
    oilType: '0W-20 Synthetic',
    insuranceCarrier: 'State Farm',
    insurancePolicy: 'SF-12345679',
    registrationExpires: '2025-01-20',
  },
];

const documentCategories: DocumentCategory[] = [
  { id: 'deeds', name: 'Deeds & Title', count: 3, icon: FileText },
  { id: 'surveys', name: 'Surveys & Plats', count: 2, icon: FileText },
  { id: 'insurance', name: 'Insurance Policies', count: 5, icon: Shield },
  { id: 'blueprints', name: 'Blueprints & Floorplans', count: 8, icon: FileText },
  { id: 'warranties', name: 'Warranties', count: 12, icon: FileText },
  { id: 'manuals', name: 'Manuals', count: 15, icon: FileText },
];

// ============================================================================
// HELPER COMPONENTS
// ============================================================================

function CopyButton({ value, className = '' }: { value: string; className?: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(value);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <button
      onClick={handleCopy}
      className={`p-2 rounded-lg hover:bg-slate-100 transition-colors ${className}`}
      title="Copy to clipboard"
    >
      {copied ? (
        <Check className="w-4 h-4 text-emerald-600" />
      ) : (
        <Copy className="w-4 h-4 text-slate-400" />
      )}
    </button>
  );
}

function MaskedValue({ value, masked }: { value: string; masked: boolean }) {
  const [revealed, setRevealed] = useState(false);

  if (!masked) {
    return <span className="font-mono text-slate-900">{value}</span>;
  }

  return (
    <div className="flex items-center gap-2">
      <span className="font-mono text-slate-900">
        {revealed ? value : '••••••••'}
      </span>
      <button
        onClick={() => setRevealed(!revealed)}
        className="p-1 rounded hover:bg-slate-100 transition-colors"
      >
        {revealed ? (
          <EyeOff className="w-4 h-4 text-slate-400" />
        ) : (
          <Eye className="w-4 h-4 text-slate-400" />
        )}
      </button>
    </div>
  );
}

function WarrantyBadge({ expiresDate }: { expiresDate: string }) {
  const expires = new Date(expiresDate);
  const today = new Date();
  const isExpired = expires < today;

  return (
    <span
      className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${
        isExpired
          ? 'bg-slate-100 text-slate-600'
          : 'bg-emerald-100 text-emerald-700'
      }`}
    >
      {isExpired ? (
        <>
          <AlertTriangle className="w-3 h-3" />
          Warranty Expired
        </>
      ) : (
        <>
          <CheckCircle2 className="w-3 h-3" />
          Under Warranty
        </>
      )}
    </span>
  );
}

function RegistrationBadge({ expiresDate }: { expiresDate: string }) {
  const expires = new Date(expiresDate);
  const today = new Date();
  const daysUntil = Math.ceil((expires.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
  const isExpiringSoon = daysUntil <= 30 && daysUntil > 0;
  const isExpired = daysUntil <= 0;

  if (isExpired) {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700">
        <AlertTriangle className="w-3 h-3" />
        Registration Expired
      </span>
    );
  }

  if (isExpiringSoon) {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
        <AlertTriangle className="w-3 h-3" />
        Expires in {daysUntil} days
      </span>
    );
  }

  return (
    <span className="text-sm text-slate-500">
      Expires {new Date(expiresDate).toLocaleDateString()}
    </span>
  );
}

// ============================================================================
// SECTION COMPONENTS
// ============================================================================

// Property Line Layer Style
const propertyLineLayerStyle = {
  id: 'property-line',
  type: 'line' as const,
  paint: {
    'line-color': '#34d399', // emerald-400
    'line-width': 3,
    'line-opacity': 0.9,
  },
};

const propertyFillLayerStyle = {
  id: 'property-fill',
  type: 'fill' as const,
  paint: {
    'fill-color': '#34d399', // emerald-400
    'fill-opacity': 0.1,
  },
};

// Hero Section with Photo/Satellite Toggle
function HeroSection() {
  const [viewMode, setViewMode] = useState<'photo' | 'satellite'>('photo');
  const mapRef = useRef<MapRef>(null);
  const [mapLoaded, setMapLoaded] = useState(false);

  // Default viewport for the property
  const defaultViewState = {
    longitude: propertyData.coordinates.longitude,
    latitude: propertyData.coordinates.latitude,
    zoom: 19,
  };

  // Reset map to center if user strays too far
  const handleMoveEnd = useCallback(() => {
    if (!mapRef.current) return;

    const center = mapRef.current.getCenter();
    const maxDistance = 0.002; // Approximately 200 meters

    const latDiff = Math.abs(center.lat - propertyData.coordinates.latitude);
    const lngDiff = Math.abs(center.lng - propertyData.coordinates.longitude);

    if (latDiff > maxDistance || lngDiff > maxDistance) {
      mapRef.current.flyTo({
        center: [propertyData.coordinates.longitude, propertyData.coordinates.latitude],
        zoom: 19,
        duration: 1000,
      });
    }
  }, []);

  // GeoJSON source for property boundary
  const propertyLineGeoJSON = {
    type: 'FeatureCollection' as const,
    features: [propertyData.propertyLine],
  };

  return (
    <div className="relative h-64 lg:h-80 rounded-xl overflow-hidden mb-6">
      {/* Photo View */}
      {viewMode === 'photo' && (
        <div className="absolute inset-0 bg-gradient-to-br from-slate-800 to-slate-900">
          {/* Placeholder gradient - replace with actual property image */}
          {/* <img src={propertyData.imageUrl} alt={propertyData.address} className="w-full h-full object-cover" /> */}
        </div>
      )}

      {/* Satellite Map View */}
      {viewMode === 'satellite' && (
        <Map
          ref={mapRef}
          initialViewState={defaultViewState}
          style={{ width: '100%', height: '100%' }}
          mapStyle="mapbox://styles/mapbox/satellite-streets-v12"
          mapboxAccessToken={process.env.NEXT_PUBLIC_MAPBOX_TOKEN}
          onLoad={() => setMapLoaded(true)}
          onMoveEnd={handleMoveEnd}
          maxZoom={21}
          minZoom={16}
          attributionControl={false}
        >
          {/* Navigation Controls */}
          <NavigationControl position="top-left" showCompass={false} />

          {/* Property Line Overlay */}
          {mapLoaded && (
            <Source id="property-boundary" type="geojson" data={propertyLineGeoJSON}>
              <Layer {...propertyFillLayerStyle} />
              <Layer {...propertyLineLayerStyle} />
            </Source>
          )}
        </Map>
      )}

      {/* Gradient overlay for text readability */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent pointer-events-none" />

      {/* View Toggle Button */}
      <div className="absolute bottom-24 lg:bottom-28 right-4 z-10">
        <div className="flex bg-white/10 backdrop-blur-md rounded-lg p-1 border border-white/20">
          <button
            onClick={() => setViewMode('photo')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm font-medium transition-all ${
              viewMode === 'photo'
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'text-white/80 hover:text-white hover:bg-white/10'
            }`}
          >
            <Image className="w-4 h-4" />
            Photo
          </button>
          <button
            onClick={() => setViewMode('satellite')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm font-medium transition-all ${
              viewMode === 'satellite'
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'text-white/80 hover:text-white hover:bg-white/10'
            }`}
          >
            <Satellite className="w-4 h-4" />
            Satellite
          </button>
        </div>
      </div>

      {/* Property Stats Overlay - Always visible */}
      <div className="absolute bottom-0 left-0 right-0 p-6 pointer-events-none">
        <h1 className="text-2xl lg:text-3xl font-bold text-white mb-2 drop-shadow-lg">
          {propertyData.address}
        </h1>
        <p className="text-slate-200 mb-4 drop-shadow">{propertyData.city}, {propertyData.state}</p>

        <div className="flex flex-wrap gap-4 pointer-events-auto">
          <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/10">
            <p className="text-xs text-slate-300">Year Built</p>
            <p className="font-semibold text-white">{propertyData.yearBuilt}</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/10">
            <p className="text-xs text-slate-300">Square Feet</p>
            <p className="font-semibold text-white">{propertyData.sqft.toLocaleString()}</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/10">
            <p className="text-xs text-slate-300">Lot Size</p>
            <p className="font-semibold text-white">{propertyData.lotSize}</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/10">
            <p className="text-xs text-slate-300">Zoning</p>
            <p className="font-semibold text-white">{propertyData.zoning}</p>
          </div>
        </div>
      </div>
    </div>
  );
}

// The Vault - Quick Access Credentials
function VaultSection() {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 mb-6">
      <div className="flex items-center gap-2 mb-4">
        <Key className="w-5 h-5 text-emerald-600" />
        <h2 className="text-lg font-semibold text-slate-900">The Vault</h2>
        <span className="text-sm text-slate-500">Quick Access Credentials</span>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {vaultItems.map((item) => {
          const Icon = item.icon;
          return (
            <div
              key={item.id}
              className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg"
            >
              <div className="p-2 bg-white rounded-lg shadow-sm">
                <Icon className="w-4 h-4 text-slate-600" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-slate-500">{item.label}</p>
                <MaskedValue value={item.value} masked={item.masked || false} />
              </div>
              <CopyButton value={item.value} />
            </div>
          );
        })}
      </div>
    </div>
  );
}

// Systems Tab
function SystemsTab() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {systemAssets.map((asset) => {
        const Icon = asset.icon;
        return (
          <div
            key={asset.id}
            className="bg-white rounded-xl shadow-sm border border-slate-200 p-6"
          >
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-emerald-50 rounded-lg">
                  <Icon className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-slate-900">{asset.name}</h3>
                  {asset.location && (
                    <p className="text-sm text-slate-500">{asset.location}</p>
                  )}
                </div>
              </div>
              <WarrantyBadge expiresDate={asset.warrantyExpires} />
            </div>

            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <p className="text-xs text-slate-500 uppercase tracking-wide">Make</p>
                <p className="font-medium text-slate-900">{asset.make}</p>
              </div>
              <div>
                <p className="text-xs text-slate-500 uppercase tracking-wide">Model</p>
                <p className="font-medium text-slate-900">{asset.model}</p>
              </div>
              <div>
                <p className="text-xs text-slate-500 uppercase tracking-wide">Serial Number</p>
                <div className="flex items-center gap-1">
                  <p className="font-mono text-sm text-slate-900">{asset.serialNumber}</p>
                  <CopyButton value={asset.serialNumber} className="p-1" />
                </div>
              </div>
              <div>
                <p className="text-xs text-slate-500 uppercase tracking-wide">Install Date</p>
                <p className="font-medium text-slate-900">
                  {new Date(asset.installDate).toLocaleDateString()}
                </p>
              </div>
            </div>

            {asset.notes && (
              <p className="text-sm text-slate-600 mb-4 p-3 bg-slate-50 rounded-lg">
                {asset.notes}
              </p>
            )}

            <Link
              href={`/app/requests/new?asset=${asset.id}`}
              className="inline-flex items-center gap-2 text-sm text-emerald-600 hover:text-emerald-700 font-medium"
            >
              <Wrench className="w-4 h-4" />
              Report Issue
            </Link>
          </div>
        );
      })}
    </div>
  );
}

// Spaces & Finishes Tab
function SpacesTab() {
  const [expandedRoom, setExpandedRoom] = useState<string | null>('kitchen');

  return (
    <div className="space-y-4">
      {roomsData.map((room) => {
        const isExpanded = expandedRoom === room.id;

        return (
          <div
            key={room.id}
            className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden"
          >
            <button
              onClick={() => setExpandedRoom(isExpanded ? null : room.id)}
              className="w-full flex items-center justify-between p-6 hover:bg-slate-50 transition-colors"
            >
              <div className="flex items-center gap-3">
                <div className="p-2 bg-emerald-50 rounded-lg">
                  <Home className="w-5 h-5 text-emerald-600" />
                </div>
                <h3 className="font-semibold text-slate-900">{room.name}</h3>
              </div>
              {isExpanded ? (
                <ChevronDown className="w-5 h-5 text-slate-400" />
              ) : (
                <ChevronRight className="w-5 h-5 text-slate-400" />
              )}
            </button>

            {isExpanded && (
              <div className="px-6 pb-6 space-y-6">
                {/* Paint Colors */}
                <div>
                  <div className="flex items-center gap-2 mb-3">
                    <Palette className="w-4 h-4 text-slate-500" />
                    <h4 className="font-medium text-slate-900">Paint Colors</h4>
                  </div>
                  <div className="flex flex-wrap gap-3">
                    {room.paint.map((color, idx) => (
                      <div
                        key={idx}
                        className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg"
                      >
                        <div
                          className="w-10 h-10 rounded-lg shadow-inner border border-slate-200"
                          style={{ backgroundColor: color.hex }}
                        />
                        <div>
                          <p className="font-medium text-slate-900">{color.name}</p>
                          <p className="text-sm text-slate-500">
                            {color.brand} - {color.code}
                          </p>
                        </div>
                        <CopyButton value={`${color.brand} ${color.name} (${color.code})`} />
                      </div>
                    ))}
                  </div>
                </div>

                {/* Flooring */}
                <div>
                  <div className="flex items-center gap-2 mb-3">
                    <Layers className="w-4 h-4 text-slate-500" />
                    <h4 className="font-medium text-slate-900">Flooring</h4>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-lg">
                    <p className="font-medium text-slate-900">{room.flooring.material}</p>
                    <p className="text-sm text-slate-500">
                      {room.flooring.brand} - SKU: {room.flooring.sku}
                    </p>
                  </div>
                </div>

                {/* Lighting */}
                <div>
                  <div className="flex items-center gap-2 mb-3">
                    <Lightbulb className="w-4 h-4 text-slate-500" />
                    <h4 className="font-medium text-slate-900">Lighting</h4>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {room.lighting.map((light, idx) => (
                      <div key={idx} className="p-3 bg-slate-50 rounded-lg">
                        <p className="font-medium text-slate-900">{light.type}</p>
                        <p className="text-sm text-slate-500">{light.bulb}</p>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Filters */}
                {room.filters && room.filters.length > 0 && (
                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <Filter className="w-4 h-4 text-slate-500" />
                      <h4 className="font-medium text-slate-900">Air Filters</h4>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      {room.filters.map((filter, idx) => (
                        <div key={idx} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                          <div>
                            <p className="font-mono font-medium text-slate-900">{filter.size}</p>
                            <p className="text-sm text-slate-500">{filter.location}</p>
                          </div>
                          <CopyButton value={filter.size} />
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

// Utilities Tab
function UtilitiesTab() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {utilityProviders.map((utility) => {
        const Icon = utility.icon;
        return (
          <div
            key={utility.id}
            className="bg-white rounded-xl shadow-sm border border-slate-200 p-6"
          >
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-blue-50 rounded-lg">
                  <Icon className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-slate-900">{utility.type}</h3>
                  <p className="text-sm text-slate-500">{utility.provider}</p>
                </div>
              </div>
              {utility.managedByHaven && (
                <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
                  <CheckCircle2 className="w-3 h-3" />
                  Managed by Haven
                </span>
              )}
            </div>

            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Account Number</span>
                <div className="flex items-center gap-1">
                  <span className="font-mono text-sm text-slate-900">{utility.accountNumber}</span>
                  <CopyButton value={utility.accountNumber} className="p-1" />
                </div>
              </div>

              {utility.meterNumber && (
                <div className="flex items-center justify-between">
                  <span className="text-sm text-slate-500">Meter Number</span>
                  <div className="flex items-center gap-1">
                    <span className="font-mono text-sm text-slate-900">{utility.meterNumber}</span>
                    <CopyButton value={utility.meterNumber} className="p-1" />
                  </div>
                </div>
              )}

              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Support</span>
                <a
                  href={`tel:${utility.supportPhone}`}
                  className="inline-flex items-center gap-1 text-sm text-emerald-600 hover:text-emerald-700"
                >
                  <Phone className="w-4 h-4" />
                  {utility.supportPhone}
                </a>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

// Vehicles Tab
function VehiclesTab() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {vehicles.map((vehicle) => (
        <div
          key={vehicle.id}
          className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden"
        >
          {/* Vehicle Header */}
          <div className="p-6 bg-gradient-to-br from-slate-800 to-slate-900 text-white">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-white/10 rounded-lg">
                <Car className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-xl font-bold">
                  {vehicle.year} {vehicle.make} {vehicle.model}
                </h3>
                <p className="text-slate-300">{vehicle.color}</p>
              </div>
            </div>
          </div>

          {/* Vehicle Details */}
          <div className="p-6 space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-slate-500 uppercase tracking-wide">VIN</p>
                <div className="flex items-center gap-1">
                  <p className="font-mono text-sm text-slate-900">{vehicle.vin}</p>
                  <CopyButton value={vehicle.vin} className="p-1" />
                </div>
              </div>
              <div>
                <p className="text-xs text-slate-500 uppercase tracking-wide">License Plate</p>
                <div className="flex items-center gap-1">
                  <p className="font-mono text-lg font-bold text-slate-900">{vehicle.licensePlate}</p>
                  <CopyButton value={vehicle.licensePlate} className="p-1" />
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-slate-500 uppercase tracking-wide">Tire Size (Front)</p>
                <p className="font-mono text-slate-900">{vehicle.tireSizeFront}</p>
              </div>
              <div>
                <p className="text-xs text-slate-500 uppercase tracking-wide">Tire Size (Rear)</p>
                <p className="font-mono text-slate-900">{vehicle.tireSizeRear}</p>
              </div>
            </div>

            <div>
              <p className="text-xs text-slate-500 uppercase tracking-wide">Oil Type</p>
              <p className="font-medium text-slate-900">{vehicle.oilType}</p>
            </div>

            <div className="pt-4 border-t border-slate-200">
              <div className="flex items-center justify-between mb-2">
                <div>
                  <p className="text-xs text-slate-500 uppercase tracking-wide">Insurance</p>
                  <p className="font-medium text-slate-900">{vehicle.insuranceCarrier}</p>
                </div>
                <div className="flex items-center gap-1">
                  <span className="font-mono text-sm text-slate-600">{vehicle.insurancePolicy}</span>
                  <CopyButton value={vehicle.insurancePolicy} className="p-1" />
                </div>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Registration</span>
                <RegistrationBadge expiresDate={vehicle.registrationExpires} />
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

// Documents Tab
function DocumentsTab() {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      {documentCategories.map((category) => {
        const Icon = category.icon;
        return (
          <Link
            key={category.id}
            href={`/app/documents?category=${category.id}`}
            className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:border-emerald-300 hover:shadow-md transition-all group"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="p-2 bg-slate-50 rounded-lg group-hover:bg-emerald-50 transition-colors">
                <Icon className="w-5 h-5 text-slate-600 group-hover:text-emerald-600 transition-colors" />
              </div>
              <span className="text-sm text-slate-500">{category.count} files</span>
            </div>
            <h3 className="font-semibold text-slate-900 group-hover:text-emerald-600 transition-colors">
              {category.name}
            </h3>
            <div className="flex items-center gap-1 mt-2 text-sm text-emerald-600 opacity-0 group-hover:opacity-100 transition-opacity">
              View Documents
              <ExternalLink className="w-4 h-4" />
            </div>
          </Link>
        );
      })}
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function HomeProfilePage() {
  const [activeTab, setActiveTab] = useState<TabId>('systems');

  const tabs: { id: TabId; label: string; icon: typeof ThermometerSun }[] = [
    { id: 'systems', label: 'Systems', icon: ThermometerSun },
    { id: 'spaces', label: 'Spaces & Finishes', icon: Palette },
    { id: 'utilities', label: 'Utilities', icon: Zap },
    { id: 'vehicles', label: 'Vehicles', icon: Car },
    { id: 'documents', label: 'Documents', icon: FileText },
  ];

  return (
    <div className="pb-32 lg:pb-8">
      {/* Hero Section */}
      <HeroSection />

      {/* The Vault */}
      <VaultSection />

      {/* Tabbed Interface */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 mb-6 sticky top-14 lg:top-0 z-30">
        <div className="flex overflow-x-auto scrollbar-hide">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-6 py-4 text-sm font-medium whitespace-nowrap border-b-2 transition-colors ${
                  isActive
                    ? 'border-emerald-600 text-emerald-600'
                    : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
                }`}
              >
                <Icon className="w-4 h-4" />
                {tab.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Tab Content */}
      <div>
        {activeTab === 'systems' && <SystemsTab />}
        {activeTab === 'spaces' && <SpacesTab />}
        {activeTab === 'utilities' && <UtilitiesTab />}
        {activeTab === 'vehicles' && <VehiclesTab />}
        {activeTab === 'documents' && <DocumentsTab />}
      </div>
    </div>
  );
}
