'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import Image from 'next/image';
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
  Camera,
  DoorOpen,
  Bell,
  Wallet,
  Flame,
  Snowflake,
  Gauge,
  Power,
} from 'lucide-react';
import { getApiClient } from '@/lib/api';
import { useAuth } from '@/contexts/auth-context';
import { CreditCard } from '@/components/credit-card';
import type {
  HomeProfile,
  HomeSystem,
  HomeSystemType,
  Vehicle,
  BillAccount,
  BillingSummary,
} from '@haven/core';

// ============================================================================
// TYPES
// ============================================================================

type TabId = 'systems' | 'spaces' | 'utilities' | 'vehicles' | 'documents' | 'wallet';

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

interface PropertyData {
  address: string;
  city: string;
  state: string;
  yearBuilt: number;
  sqft: number;
  lotSize: string;
  zoning: string;
  imageUrl: string;
}

interface FinancialsData {
  spendingLimit: number;
  currentSpend: number;
  cardName: string;
  cardHolder: string;
  last4: string;
  expiry: string;
  isLocked: boolean;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const MOCK_PROPERTY_DATA: PropertyData = {
  address: "1247 Beverly Drive",
  city: "Beverly Hills",
  state: "CA",
  yearBuilt: 2018,
  sqft: 4200,
  lotSize: "0.35 acres",
  zoning: "Res-A",
  imageUrl: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1600&q=80",
};

const MOCK_VAULT_ITEMS: VaultItem[] = [
  { id: 'wifi', label: 'WiFi Network', value: 'HomeNetwork_5G / Tr0ub4dor&3', icon: Wifi, masked: true },
  { id: 'alarm', label: 'Alarm Code', value: '4729', icon: Shield, masked: true },
  { id: 'safe', label: 'Safe Combination', value: '24-08-16', icon: Shield, masked: true },
  { id: 'gate', label: 'Gate Code', value: '#1247', icon: Key, masked: false },
  { id: 'garage', label: 'Garage Keypad', value: '7294', icon: Key, masked: true },
  { id: 'trash', label: 'Trash Day', value: 'Tuesday', icon: Trash2, masked: false },
  { id: 'mailbox', label: 'Mailbox #', value: '247', icon: Mailbox, masked: false },
];

const MOCK_SYSTEMS: SystemAsset[] = [
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

const MOCK_ROOMS_DATA: RoomData[] = [
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

const MOCK_UTILITIES: UtilityProvider[] = [
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

const MOCK_VEHICLES: VehicleData[] = [
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

const MOCK_DOCUMENT_CATEGORIES: DocumentCategory[] = [
  { id: 'deeds', name: 'Deeds & Title', count: 3, icon: FileText },
  { id: 'surveys', name: 'Surveys & Plats', count: 2, icon: FileText },
  { id: 'insurance', name: 'Insurance Policies', count: 5, icon: Shield },
  { id: 'blueprints', name: 'Blueprints & Floorplans', count: 8, icon: FileText },
  { id: 'warranties', name: 'Warranties', count: 12, icon: FileText },
  { id: 'manuals', name: 'Manuals', count: 15, icon: FileText },
];

const MOCK_FINANCIALS: FinancialsData = {
  spendingLimit: 5000,
  currentSpend: 1240,
  cardName: 'Haven Household',
  cardHolder: 'Burke Family',
  last4: '4242',
  expiry: '12/27',
  isLocked: false,
};

// ============================================================================
// DATA MAPPING FUNCTIONS
// ============================================================================

function getSystemIcon(systemType: HomeSystemType): typeof ThermometerSun {
  switch (systemType) {
    case 'FURNACE':
    case 'BOILER':
    case 'FIREPLACE':
      return Flame;
    case 'AIR_CONDITIONER':
      return Snowflake;
    case 'HEAT_PUMP':
    case 'THERMOSTAT':
      return ThermometerSun;
    case 'WATER_HEATER':
    case 'SUMP_PUMP':
    case 'WELL_PUMP':
    case 'WATER_SOFTENER':
      return Droplets;
    case 'ELECTRICAL_PANEL':
    case 'GENERATOR':
      return Zap;
    case 'SOLAR_PANELS':
    case 'BATTERY_STORAGE':
      return Sun;
    case 'POOL_EQUIPMENT':
    case 'HOT_TUB':
    case 'IRRIGATION_SYSTEM':
      return Droplets;
    case 'GARAGE_DOOR_OPENER':
      return DoorOpen;
    case 'SECURITY_SYSTEM':
    case 'SMOKE_DETECTOR':
    case 'CO_DETECTOR':
    case 'FIRE_EXTINGUISHER':
      return Shield;
    case 'CEILING_FAN':
      return Wind;
    case 'REFRIGERATOR':
    case 'DISHWASHER':
    case 'OVEN_RANGE':
    case 'MICROWAVE':
    case 'GARBAGE_DISPOSAL':
    case 'WASHER':
    case 'DRYER':
      return Power;
    case 'LAWN_MOWER':
      return Gauge;
    default:
      return ThermometerSun;
  }
}

function mapProfileToDisplay(apiProfile: HomeProfile): PropertyData {
  // Convert lotSize (number of sq ft or acres) to display string
  const lotSizeDisplay = apiProfile.lotSize
    ? apiProfile.lotSize >= 43560
      ? `${(apiProfile.lotSize / 43560).toFixed(2)} acres`
      : `${apiProfile.lotSize.toLocaleString()} sq ft`
    : MOCK_PROPERTY_DATA.lotSize;

  return {
    address: apiProfile.addressLine1 || MOCK_PROPERTY_DATA.address,
    city: apiProfile.city || MOCK_PROPERTY_DATA.city,
    state: apiProfile.state || MOCK_PROPERTY_DATA.state,
    yearBuilt: apiProfile.yearBuilt || MOCK_PROPERTY_DATA.yearBuilt,
    sqft: apiProfile.squareFeet || MOCK_PROPERTY_DATA.sqft,
    lotSize: lotSizeDisplay,
    zoning: MOCK_PROPERTY_DATA.zoning, // zoning not in API, use mock
    imageUrl: MOCK_PROPERTY_DATA.imageUrl, // Use mock image as fallback
  };
}

function mapSystemToAsset(apiSystem: HomeSystem): SystemAsset {
  return {
    id: apiSystem.id,
    name: apiSystem.name || apiSystem.systemType,
    icon: getSystemIcon(apiSystem.systemType),
    make: apiSystem.brand || 'Unknown',
    model: apiSystem.model || 'Unknown',
    serialNumber: apiSystem.serialNumber || 'N/A',
    installDate: apiSystem.installDate || '',
    warrantyExpires: apiSystem.warrantyExpires || '',
    location: apiSystem.location || undefined,
    notes: apiSystem.notes || undefined,
  };
}

function mapVehicleToDisplay(apiVehicle: Vehicle): VehicleData {
  return {
    id: apiVehicle.id,
    year: apiVehicle.year || new Date().getFullYear(),
    make: apiVehicle.make || 'Unknown',
    model: apiVehicle.model || 'Unknown',
    color: apiVehicle.color || 'Unknown',
    vin: apiVehicle.vin || 'N/A',
    licensePlate: apiVehicle.licensePlate || 'N/A',
    tireSizeFront: 'See manual', // Not in API, would need extended fields
    tireSizeRear: 'See manual',
    oilType: 'Consult manual', // Not in API, would need extended fields
    insuranceCarrier: apiVehicle.insuranceProvider || 'Not on file',
    insurancePolicy: apiVehicle.insurancePolicyNum || 'N/A',
    registrationExpires: apiVehicle.registrationExpires || '',
    imageUrl: apiVehicle.photoUrls?.[0] || undefined,
  };
}

function mapBillAccountToUtility(billAccount: BillAccount): UtilityProvider | null {
  // Only map utility-type bill accounts
  const utilityCategories = ['UTILITY', 'ELECTRIC', 'GAS', 'WATER', 'INTERNET', 'TRASH'];
  if (!utilityCategories.includes(billAccount.category)) {
    return null;
  }

  const iconMap: Record<string, typeof Zap> = {
    ELECTRIC: Zap,
    GAS: Wind,
    WATER: Droplets,
    INTERNET: Wifi,
    TRASH: Trash2,
    UTILITY: Zap,
  };

  return {
    id: billAccount.id,
    type: billAccount.category,
    icon: iconMap[billAccount.category] || Zap,
    provider: billAccount.nickname,
    accountNumber: billAccount.accountNumber || 'On file',
    meterNumber: undefined,
    supportPhone: 'See bill',
    managedByHaven: true,
  };
}

function mapFinancials(billingSummary: BillingSummary): FinancialsData {
  return {
    spendingLimit: 5000, // Default limit
    currentSpend: billingSummary.monthlyBillEstimate || 0,
    cardName: 'Haven Household',
    cardHolder: 'Burke Family',
    last4: '4242',
    expiry: '12/27',
    isLocked: false,
  };
}

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
      className={`p-2 rounded-lg hover:bg-warm-100 transition-colors ${className}`}
      title="Copy to clipboard"
    >
      {copied ? (
        <Check className="w-4 h-4 text-emerald-600" />
      ) : (
        <Copy className="w-4 h-4 text-warm-400" />
      )}
    </button>
  );
}

function MaskedValue({ value, masked }: { value: string; masked: boolean }) {
  const [revealed, setRevealed] = useState(false);

  if (!masked) {
    return <span className="font-mono text-warm-900">{value}</span>;
  }

  return (
    <div className="flex items-center gap-2">
      <span className="font-mono text-warm-900">
        {revealed ? value : '••••••••'}
      </span>
      <button
        onClick={() => setRevealed(!revealed)}
        className="p-1 rounded hover:bg-warm-100 transition-colors"
      >
        {revealed ? (
          <EyeOff className="w-4 h-4 text-warm-400" />
        ) : (
          <Eye className="w-4 h-4 text-warm-400" />
        )}
      </button>
    </div>
  );
}

function WarrantyBadge({ expiresDate }: { expiresDate: string }) {
  if (!expiresDate) return null;
  const expires = new Date(expiresDate);
  const today = new Date();
  const isExpired = expires < today;

  return (
    <span
      className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${
        isExpired
          ? 'bg-warm-100 text-warm-600'
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
  if (!expiresDate) return null;
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
    <span className="text-sm text-warm-500">
      Expires {new Date(expiresDate).toLocaleDateString()}
    </span>
  );
}

// ============================================================================
// SECTION COMPONENTS
// ============================================================================

// Hero Section - Cinematic Property Header
function HeroSection({ property }: { property: PropertyData }) {
  return (
    <>
      {/* Desktop & Tablet Layout */}
      <div className="relative h-[300px] lg:h-[400px] rounded-xl overflow-hidden mb-6 hidden sm:block">
        {/* Property Photo Background */}
        <div className="absolute inset-0">
          {property.imageUrl ? (
            <Image
              src={property.imageUrl}
              alt={property.address}
              fill
              className="object-cover"
              priority
            />
          ) : (
            // Fallback gradient when no image
            <div className="w-full h-full bg-gradient-to-br from-emerald-900 via-warm-800 to-warm-900" />
          )}
        </div>

        {/* Gradient Overlay for Readability */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />

        {/* Edit Cover Photo Button - Top Right */}
        <button className="absolute top-4 right-4 z-10 flex items-center gap-2 px-3 py-2 bg-black/30 backdrop-blur-sm rounded-lg border border-white/20 text-white/90 hover:bg-black/50 hover:text-white transition-all">
          <Camera className="w-4 h-4" />
          <span className="text-sm font-medium">Edit Cover</span>
        </button>

        {/* Content Layer - Bottom Left */}
        <div className="absolute bottom-0 left-0 right-0 p-6 lg:p-8">
          <div className="flex items-end justify-between">
            {/* Address & Stats */}
            <div>
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-2xl lg:text-3xl font-bold text-white drop-shadow-lg">
                  {property.address}
                </h1>
                <span className="inline-flex items-center gap-1 px-2 py-1 bg-emerald-500/90 backdrop-blur-sm rounded-full text-xs font-semibold text-white">
                  <Shield className="w-3 h-3" />
                  Haven Managed
                </span>
              </div>
              <p className="text-warm-200 mb-4 drop-shadow">{property.city}, {property.state}</p>

              {/* Property Stats */}
              <div className="flex flex-wrap gap-3">
                <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/10">
                  <p className="text-xs text-warm-300">Year Built</p>
                  <p className="font-semibold text-white">{property.yearBuilt}</p>
                </div>
                <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/10">
                  <p className="text-xs text-warm-300">Square Feet</p>
                  <p className="font-semibold text-white">{property.sqft.toLocaleString()}</p>
                </div>
                <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/10">
                  <p className="text-xs text-warm-300">Lot Size</p>
                  <p className="font-semibold text-white">{property.lotSize}</p>
                </div>
                <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/10">
                  <p className="text-xs text-warm-300">Zoning</p>
                  <p className="font-semibold text-white">{property.zoning}</p>
                </div>
              </div>
            </div>

            {/* Quick Access Dock - Bottom Right (Desktop) */}
            <div className="hidden lg:flex backdrop-blur-xl bg-white/10 rounded-2xl border border-white/20 p-2 gap-2">
              <button className="flex flex-col items-center gap-1 p-3 rounded-xl hover:bg-white/10 transition-colors group">
                <div className="p-2 bg-white/20 rounded-lg group-hover:bg-emerald-500/80 transition-colors">
                  <Wifi className="w-5 h-5 text-white" />
                </div>
                <span className="text-xs text-white/80 font-medium">WiFi</span>
              </button>
              <button className="flex flex-col items-center gap-1 p-3 rounded-xl hover:bg-white/10 transition-colors group">
                <div className="p-2 bg-white/20 rounded-lg group-hover:bg-emerald-500/80 transition-colors">
                  <DoorOpen className="w-5 h-5 text-white" />
                </div>
                <span className="text-xs text-white/80 font-medium">Gate</span>
              </button>
              <button className="flex flex-col items-center gap-1 p-3 rounded-xl hover:bg-white/10 transition-colors group">
                <div className="p-2 bg-white/20 rounded-lg group-hover:bg-emerald-500/80 transition-colors">
                  <Bell className="w-5 h-5 text-white" />
                </div>
                <span className="text-xs text-white/80 font-medium">Alarm</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Mobile Layout - Dock Below Image */}
      <div className="sm:hidden mb-6">
        {/* Property Photo */}
        <div className="relative h-[200px] rounded-xl overflow-hidden mb-4">
          <div className="absolute inset-0">
            {property.imageUrl ? (
              <Image
                src={property.imageUrl}
                alt={property.address}
                fill
                className="object-cover"
                priority
              />
            ) : (
              <div className="w-full h-full bg-gradient-to-br from-emerald-900 via-warm-800 to-warm-900" />
            )}
          </div>

          {/* Gradient Overlay */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />

          {/* Edit Cover Button */}
          <button className="absolute top-3 right-3 z-10 p-2 bg-black/30 backdrop-blur-sm rounded-lg border border-white/20 text-white/90 hover:bg-black/50 transition-all">
            <Camera className="w-4 h-4" />
          </button>

          {/* Address Overlay */}
          <div className="absolute bottom-0 left-0 right-0 p-4">
            <div className="flex items-center gap-2 mb-1">
              <h1 className="text-xl font-bold text-white drop-shadow-lg">
                {property.address}
              </h1>
            </div>
            <div className="flex items-center gap-2">
              <p className="text-warm-200 text-sm">{property.city}, {property.state}</p>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-500/90 backdrop-blur-sm rounded-full text-xs font-semibold text-white">
                <Shield className="w-3 h-3" />
                Haven Managed
              </span>
            </div>
          </div>
        </div>

        {/* Property Stats - Mobile */}
        <div className="grid grid-cols-4 gap-2 mb-4">
          <div className="bg-warm-100 rounded-lg px-3 py-2 text-center">
            <p className="text-xs text-warm-500">Built</p>
            <p className="font-semibold text-warm-900 text-sm">{property.yearBuilt}</p>
          </div>
          <div className="bg-warm-100 rounded-lg px-3 py-2 text-center">
            <p className="text-xs text-warm-500">Sq Ft</p>
            <p className="font-semibold text-warm-900 text-sm">{property.sqft.toLocaleString()}</p>
          </div>
          <div className="bg-warm-100 rounded-lg px-3 py-2 text-center">
            <p className="text-xs text-warm-500">Lot</p>
            <p className="font-semibold text-warm-900 text-sm">{property.lotSize}</p>
          </div>
          <div className="bg-warm-100 rounded-lg px-3 py-2 text-center">
            <p className="text-xs text-warm-500">Zone</p>
            <p className="font-semibold text-warm-900 text-sm">{property.zoning}</p>
          </div>
        </div>

        {/* Quick Access Dock - Mobile (Below Image) */}
        <div className="flex justify-center">
          <div className="flex bg-white rounded-2xl shadow-sm border border-warm-200 p-2 gap-2">
            <button className="flex flex-col items-center gap-1 p-3 rounded-xl hover:bg-warm-50 transition-colors group">
              <div className="p-2 bg-warm-100 rounded-lg group-hover:bg-emerald-100 transition-colors">
                <Wifi className="w-5 h-5 text-warm-600 group-hover:text-emerald-600" />
              </div>
              <span className="text-xs text-warm-600 font-medium">WiFi</span>
            </button>
            <button className="flex flex-col items-center gap-1 p-3 rounded-xl hover:bg-warm-50 transition-colors group">
              <div className="p-2 bg-warm-100 rounded-lg group-hover:bg-emerald-100 transition-colors">
                <DoorOpen className="w-5 h-5 text-warm-600 group-hover:text-emerald-600" />
              </div>
              <span className="text-xs text-warm-600 font-medium">Gate</span>
            </button>
            <button className="flex flex-col items-center gap-1 p-3 rounded-xl hover:bg-warm-50 transition-colors group">
              <div className="p-2 bg-warm-100 rounded-lg group-hover:bg-emerald-100 transition-colors">
                <Bell className="w-5 h-5 text-warm-600 group-hover:text-emerald-600" />
              </div>
              <span className="text-xs text-warm-600 font-medium">Alarm</span>
            </button>
          </div>
        </div>
      </div>
    </>
  );
}

// The Vault - Quick Access Credentials
function VaultSection() {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-6 mb-6">
      <div className="flex items-center gap-2 mb-4">
        <Key className="w-5 h-5 text-emerald-600" />
        <h2 className="text-lg font-semibold text-warm-900">The Vault</h2>
        <span className="text-sm text-warm-500">Quick Access Credentials</span>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {MOCK_VAULT_ITEMS.map((item) => {
          const Icon = item.icon;
          return (
            <div
              key={item.id}
              className="flex items-center gap-3 p-3 bg-warm-50 rounded-lg"
            >
              <div className="p-2 bg-white rounded-lg shadow-sm">
                <Icon className="w-4 h-4 text-warm-600" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-warm-500">{item.label}</p>
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
function SystemsTab({ systems }: { systems: SystemAsset[] }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {systems.map((asset) => {
        const Icon = asset.icon;
        return (
          <div
            key={asset.id}
            className="bg-white rounded-xl shadow-sm border border-warm-200 p-6"
          >
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-emerald-50 rounded-lg">
                  <Icon className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-warm-900">{asset.name}</h3>
                  {asset.location && (
                    <p className="text-sm text-warm-500">{asset.location}</p>
                  )}
                </div>
              </div>
              <WarrantyBadge expiresDate={asset.warrantyExpires} />
            </div>

            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <p className="text-xs text-warm-500 uppercase tracking-wide">Make</p>
                <p className="font-medium text-warm-900">{asset.make}</p>
              </div>
              <div>
                <p className="text-xs text-warm-500 uppercase tracking-wide">Model</p>
                <p className="font-medium text-warm-900">{asset.model}</p>
              </div>
              <div>
                <p className="text-xs text-warm-500 uppercase tracking-wide">Serial Number</p>
                <div className="flex items-center gap-1">
                  <p className="font-mono text-sm text-warm-900">{asset.serialNumber}</p>
                  <CopyButton value={asset.serialNumber} className="p-1" />
                </div>
              </div>
              <div>
                <p className="text-xs text-warm-500 uppercase tracking-wide">Install Date</p>
                <p className="font-medium text-warm-900">
                  {asset.installDate ? new Date(asset.installDate).toLocaleDateString() : 'N/A'}
                </p>
              </div>
            </div>

            {asset.notes && (
              <p className="text-sm text-warm-600 mb-4 p-3 bg-warm-50 rounded-lg">
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
      {MOCK_ROOMS_DATA.map((room) => {
        const isExpanded = expandedRoom === room.id;

        return (
          <div
            key={room.id}
            className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden"
          >
            <button
              onClick={() => setExpandedRoom(isExpanded ? null : room.id)}
              className="w-full flex items-center justify-between p-6 hover:bg-warm-50 transition-colors"
            >
              <div className="flex items-center gap-3">
                <div className="p-2 bg-emerald-50 rounded-lg">
                  <Home className="w-5 h-5 text-emerald-600" />
                </div>
                <h3 className="font-semibold text-warm-900">{room.name}</h3>
              </div>
              {isExpanded ? (
                <ChevronDown className="w-5 h-5 text-warm-400" />
              ) : (
                <ChevronRight className="w-5 h-5 text-warm-400" />
              )}
            </button>

            {isExpanded && (
              <div className="px-6 pb-6 space-y-6">
                {/* Paint Colors */}
                <div>
                  <div className="flex items-center gap-2 mb-3">
                    <Palette className="w-4 h-4 text-warm-500" />
                    <h4 className="font-medium text-warm-900">Paint Colors</h4>
                  </div>
                  <div className="flex flex-wrap gap-3">
                    {room.paint.map((color, idx) => (
                      <div
                        key={idx}
                        className="flex items-center gap-3 p-3 bg-warm-50 rounded-lg"
                      >
                        <div
                          className="w-10 h-10 rounded-lg shadow-inner border border-warm-200"
                          style={{ backgroundColor: color.hex }}
                        />
                        <div>
                          <p className="font-medium text-warm-900">{color.name}</p>
                          <p className="text-sm text-warm-500">
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
                    <Layers className="w-4 h-4 text-warm-500" />
                    <h4 className="font-medium text-warm-900">Flooring</h4>
                  </div>
                  <div className="p-3 bg-warm-50 rounded-lg">
                    <p className="font-medium text-warm-900">{room.flooring.material}</p>
                    <p className="text-sm text-warm-500">
                      {room.flooring.brand} - SKU: {room.flooring.sku}
                    </p>
                  </div>
                </div>

                {/* Lighting */}
                <div>
                  <div className="flex items-center gap-2 mb-3">
                    <Lightbulb className="w-4 h-4 text-warm-500" />
                    <h4 className="font-medium text-warm-900">Lighting</h4>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {room.lighting.map((light, idx) => (
                      <div key={idx} className="p-3 bg-warm-50 rounded-lg">
                        <p className="font-medium text-warm-900">{light.type}</p>
                        <p className="text-sm text-warm-500">{light.bulb}</p>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Filters */}
                {room.filters && room.filters.length > 0 && (
                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <Filter className="w-4 h-4 text-warm-500" />
                      <h4 className="font-medium text-warm-900">Air Filters</h4>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      {room.filters.map((filter, idx) => (
                        <div key={idx} className="flex items-center justify-between p-3 bg-warm-50 rounded-lg">
                          <div>
                            <p className="font-mono font-medium text-warm-900">{filter.size}</p>
                            <p className="text-sm text-warm-500">{filter.location}</p>
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
function UtilitiesTab({ utilities }: { utilities: UtilityProvider[] }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {utilities.map((utility) => {
        const Icon = utility.icon;
        return (
          <div
            key={utility.id}
            className="bg-white rounded-xl shadow-sm border border-warm-200 p-6"
          >
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-blue-50 rounded-lg">
                  <Icon className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-warm-900">{utility.type}</h3>
                  <p className="text-sm text-warm-500">{utility.provider}</p>
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
                <span className="text-sm text-warm-500">Account Number</span>
                <div className="flex items-center gap-1">
                  <span className="font-mono text-sm text-warm-900">{utility.accountNumber}</span>
                  <CopyButton value={utility.accountNumber} className="p-1" />
                </div>
              </div>

              {utility.meterNumber && (
                <div className="flex items-center justify-between">
                  <span className="text-sm text-warm-500">Meter Number</span>
                  <div className="flex items-center gap-1">
                    <span className="font-mono text-sm text-warm-900">{utility.meterNumber}</span>
                    <CopyButton value={utility.meterNumber} className="p-1" />
                  </div>
                </div>
              )}

              <div className="flex items-center justify-between">
                <span className="text-sm text-warm-500">Support</span>
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
function VehiclesTab({ vehicles }: { vehicles: VehicleData[] }) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {vehicles.map((vehicle) => (
        <div
          key={vehicle.id}
          className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden"
        >
          {/* Vehicle Header */}
          <div className="p-6 bg-gradient-to-br from-warm-800 to-warm-900 text-white">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-white/10 rounded-lg">
                <Car className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-xl font-bold">
                  {vehicle.year} {vehicle.make} {vehicle.model}
                </h3>
                <p className="text-warm-300">{vehicle.color}</p>
              </div>
            </div>
          </div>

          {/* Vehicle Details */}
          <div className="p-6 space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-warm-500 uppercase tracking-wide">VIN</p>
                <div className="flex items-center gap-1">
                  <p className="font-mono text-sm text-warm-900">{vehicle.vin}</p>
                  <CopyButton value={vehicle.vin} className="p-1" />
                </div>
              </div>
              <div>
                <p className="text-xs text-warm-500 uppercase tracking-wide">License Plate</p>
                <div className="flex items-center gap-1">
                  <p className="font-mono text-lg font-bold text-warm-900">{vehicle.licensePlate}</p>
                  <CopyButton value={vehicle.licensePlate} className="p-1" />
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-warm-500 uppercase tracking-wide">Tire Size (Front)</p>
                <p className="font-mono text-warm-900">{vehicle.tireSizeFront}</p>
              </div>
              <div>
                <p className="text-xs text-warm-500 uppercase tracking-wide">Tire Size (Rear)</p>
                <p className="font-mono text-warm-900">{vehicle.tireSizeRear}</p>
              </div>
            </div>

            <div>
              <p className="text-xs text-warm-500 uppercase tracking-wide">Oil Type</p>
              <p className="font-medium text-warm-900">{vehicle.oilType}</p>
            </div>

            <div className="pt-4 border-t border-warm-200">
              <div className="flex items-center justify-between mb-2">
                <div>
                  <p className="text-xs text-warm-500 uppercase tracking-wide">Insurance</p>
                  <p className="font-medium text-warm-900">{vehicle.insuranceCarrier}</p>
                </div>
                <div className="flex items-center gap-1">
                  <span className="font-mono text-sm text-warm-600">{vehicle.insurancePolicy}</span>
                  <CopyButton value={vehicle.insurancePolicy} className="p-1" />
                </div>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-warm-500">Registration</span>
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
      {MOCK_DOCUMENT_CATEGORIES.map((category) => {
        const Icon = category.icon;
        return (
          <Link
            key={category.id}
            href={`/app/documents?category=${category.id}`}
            className="bg-white rounded-xl shadow-sm border border-warm-200 p-6 hover:border-emerald-300 hover:shadow-md transition-all group"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="p-2 bg-warm-50 rounded-lg group-hover:bg-emerald-50 transition-colors">
                <Icon className="w-5 h-5 text-warm-600 group-hover:text-emerald-600 transition-colors" />
              </div>
              <span className="text-sm text-warm-500">{category.count} files</span>
            </div>
            <h3 className="font-semibold text-warm-900 group-hover:text-emerald-600 transition-colors">
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

// Wallet Tab - Credit Card & Spend Power
function WalletTab({ financials, onToggleLock }: { financials: FinancialsData; onToggleLock: (locked: boolean) => void }) {
  const available = financials.spendingLimit - financials.currentSpend;
  const utilization = (financials.currentSpend / financials.spendingLimit) * 100;

  // Color-coded utilization
  const getUtilizationColor = () => {
    if (utilization >= 90) return 'text-red-600';
    if (utilization >= 75) return 'text-amber-600';
    return 'text-emerald-600';
  };

  const getProgressColor = () => {
    if (utilization >= 90) return 'stroke-red-500';
    if (utilization >= 75) return 'stroke-amber-500';
    return 'stroke-emerald-500';
  };

  return (
    <div className="space-y-6">
      {/* Card & Spend Power Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Credit Card */}
        <div className="flex justify-center lg:justify-start">
          <CreditCard
            cardholderName={financials.cardHolder}
            lastFour={financials.last4}
            expiry={financials.expiry}
            isLocked={financials.isLocked}
            onToggleLock={onToggleLock}
          />
        </div>

        {/* Spend Power Summary */}
        <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-6">
          <h3 className="text-lg font-semibold text-warm-900 mb-4 flex items-center gap-2">
            <Wallet className="w-5 h-5 text-emerald-600" />
            Spend Power
          </h3>

          <div className="flex items-center gap-6">
            {/* Circular Progress Gauge */}
            <div className="relative w-32 h-32 flex-shrink-0">
              <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
                {/* Background circle */}
                <circle
                  cx="50"
                  cy="50"
                  r="40"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="8"
                  className="text-warm-200"
                />
                {/* Progress circle */}
                <circle
                  cx="50"
                  cy="50"
                  r="40"
                  fill="none"
                  strokeWidth="8"
                  strokeLinecap="round"
                  strokeDasharray={`${utilization * 2.51} 251`}
                  className={getProgressColor()}
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className={`text-2xl font-bold ${getUtilizationColor()}`}>
                  {Math.round(utilization)}%
                </span>
                <span className="text-xs text-warm-500">Used</span>
              </div>
            </div>

            {/* Stats */}
            <div className="space-y-4 flex-1">
              <div>
                <p className="text-sm text-warm-500">Available</p>
                <p className="text-2xl font-bold text-emerald-600">
                  ${available.toLocaleString()}
                </p>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-xs text-warm-500">Monthly Limit</p>
                  <p className="font-semibold text-warm-900">
                    ${financials.spendingLimit.toLocaleString()}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-warm-500">Current Spend</p>
                  <p className="font-semibold text-warm-900">
                    ${financials.currentSpend.toLocaleString()}
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Quick Actions */}
          <div className="mt-6 pt-4 border-t border-warm-200 flex gap-3">
            <Link
              href="/app/billing"
              className="flex-1 px-4 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition-colors text-center"
            >
              View Transactions
            </Link>
            <Link
              href="/app/billing?tab=statements"
              className="flex-1 px-4 py-2 bg-warm-100 text-warm-700 text-sm font-medium rounded-lg hover:bg-warm-200 transition-colors text-center"
            >
              Pay Statement
            </Link>
          </div>
        </div>
      </div>

      {/* Card Info */}
      <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-6">
        <h3 className="text-lg font-semibold text-warm-900 mb-4">Card Details</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <p className="text-xs text-warm-500 uppercase tracking-wide">Card Name</p>
            <p className="font-medium text-warm-900">{financials.cardName}</p>
          </div>
          <div>
            <p className="text-xs text-warm-500 uppercase tracking-wide">Cardholder</p>
            <p className="font-medium text-warm-900">{financials.cardHolder}</p>
          </div>
          <div>
            <p className="text-xs text-warm-500 uppercase tracking-wide">Status</p>
            <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${
              financials.isLocked
                ? 'bg-red-100 text-red-700'
                : 'bg-emerald-100 text-emerald-700'
            }`}>
              {financials.isLocked ? 'Locked' : 'Active'}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function HomeProfilePage() {
  const { currentHousehold } = useAuth();
  const [activeTab, setActiveTab] = useState<TabId>('systems');

  // State initialized with mock defaults for hybrid data pattern
  const [property, setProperty] = useState<PropertyData>(MOCK_PROPERTY_DATA);
  const [systems, setSystems] = useState<SystemAsset[]>(MOCK_SYSTEMS);
  const [vehicles, setVehicles] = useState<VehicleData[]>(MOCK_VEHICLES);
  const [utilities, setUtilities] = useState<UtilityProvider[]>(MOCK_UTILITIES);
  const [financials, setFinancials] = useState<FinancialsData>(MOCK_FINANCIALS);

  // Load data from API with hybrid fallback
  const loadDashboardData = useCallback(async () => {
    if (!currentHousehold?.id) return;

    const api = getApiClient();
    const householdId = currentHousehold.id;

    // Use Promise.allSettled for independent data streams
    const results = await Promise.allSettled([
      api.getHomeProfile(householdId),
      api.getHomeSystems(),
      api.getFamilyVehicles(),
      api.getBillAccounts(householdId),
      api.getBillingSummary(householdId),
    ]);

    // Process each result - only update state if fulfilled with data
    const [profileResult, systemsResult, vehiclesResult, billAccountsResult, billingSummaryResult] = results;

    // Home Profile
    if (profileResult.status === 'fulfilled' && profileResult.value) {
      setProperty(mapProfileToDisplay(profileResult.value));
    }

    // Home Systems
    if (systemsResult.status === 'fulfilled' && systemsResult.value?.length > 0) {
      setSystems(systemsResult.value.map(mapSystemToAsset));
    }

    // Vehicles
    if (vehiclesResult.status === 'fulfilled' && vehiclesResult.value?.length > 0) {
      setVehicles(vehiclesResult.value.map(mapVehicleToDisplay));
    }

    // Bill Accounts → Utilities
    if (billAccountsResult.status === 'fulfilled' && billAccountsResult.value?.length > 0) {
      const mappedUtilities = billAccountsResult.value
        .map(mapBillAccountToUtility)
        .filter((u): u is UtilityProvider => u !== null);
      if (mappedUtilities.length > 0) {
        setUtilities(mappedUtilities);
      }
    }

    // Billing Summary → Financials
    if (billingSummaryResult.status === 'fulfilled' && billingSummaryResult.value) {
      setFinancials(prev => ({
        ...prev,
        ...mapFinancials(billingSummaryResult.value),
      }));
    }
  }, [currentHousehold?.id]);

  // Fetch data on mount
  useEffect(() => {
    loadDashboardData();
  }, [loadDashboardData]);

  // Handle card lock toggle
  const handleCardLockToggle = useCallback((locked: boolean) => {
    setFinancials(prev => ({ ...prev, isLocked: locked }));
    // TODO: Call API to persist lock state
  }, []);

  const tabs: { id: TabId; label: string; icon: typeof ThermometerSun }[] = [
    { id: 'systems', label: 'Systems', icon: ThermometerSun },
    { id: 'spaces', label: 'Spaces & Finishes', icon: Palette },
    { id: 'utilities', label: 'Utilities', icon: Zap },
    { id: 'vehicles', label: 'Vehicles', icon: Car },
    { id: 'documents', label: 'Documents', icon: FileText },
    { id: 'wallet', label: 'Wallet', icon: Wallet },
  ];

  return (
    <div className="pb-32 lg:pb-8">
      {/* Hero Section */}
      <HeroSection property={property} />

      {/* The Vault */}
      <VaultSection />

      {/* Tabbed Interface */}
      <div className="bg-white rounded-xl shadow-sm border border-warm-200 mb-6 sticky top-14 lg:top-0 z-30">
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
                    : 'border-transparent text-warm-500 hover:text-warm-700 hover:border-warm-300'
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
        {activeTab === 'systems' && <SystemsTab systems={systems} />}
        {activeTab === 'spaces' && <SpacesTab />}
        {activeTab === 'utilities' && <UtilitiesTab utilities={utilities} />}
        {activeTab === 'vehicles' && <VehiclesTab vehicles={vehicles} />}
        {activeTab === 'documents' && <DocumentsTab />}
        {activeTab === 'wallet' && <WalletTab financials={financials} onToggleLock={handleCardLockToggle} />}
      </div>
    </div>
  );
}
