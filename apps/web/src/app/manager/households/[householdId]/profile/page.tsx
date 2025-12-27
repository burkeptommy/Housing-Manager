'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Home,
  Plus,
  ChevronRight,
  Sparkles,
  Loader2,
  CheckCircle,
  Camera,
  Wrench,
  Building2,
  Refrigerator,
  Flame,
  Droplets,
  Zap,
  Car,
  Leaf,
  Waves,
  Settings,
  FileText,
  Users,
  Phone,
} from 'lucide-react';
import { getIdToken } from '@/lib/firebase';

// ===========================================================================
// TYPES
// ===========================================================================

interface Zone {
  id: string;
  name: string;
  type: string;
  floor?: string;
  photos: string[];
  notes?: string;
  procedures?: string;
  assetCount: number;
}

interface PropertyAsset {
  id: string;
  name: string;
  category: string;
  brand?: string;
  model?: string;
  condition?: string;
  zoneId?: string;
  serviceVendorId?: string;
  lastServiceDate?: string;
  nextServiceDate?: string;
}

interface Household {
  id: string;
  name: string;
  homeProfile?: {
    addressLine1: string;
    city: string;
    state: string;
    postalCode: string;
    bedrooms?: number;
    bathrooms?: number;
    squareFeet?: number;
    yearBuilt?: number;
  };
  owner: {
    firstName?: string;
    lastName?: string;
    email: string;
    phone?: string;
  };
  onboardingProgress?: {
    status: string;
    zonesComplete: number;
    assetsComplete: number;
    vendorsComplete: number;
  };
  enrichmentData?: Record<string, unknown>;
}

// ===========================================================================
// ZONE TYPE ICONS AND LABELS
// ===========================================================================

const ZONE_TYPES = {
  KITCHEN: { icon: Refrigerator, label: 'Kitchen', color: 'bg-amber-100 text-amber-600' },
  LIVING_ROOM: { icon: Home, label: 'Living Room', color: 'bg-blue-100 text-blue-600' },
  DINING_ROOM: { icon: Home, label: 'Dining Room', color: 'bg-purple-100 text-purple-600' },
  BEDROOM: { icon: Home, label: 'Bedroom', color: 'bg-indigo-100 text-indigo-600' },
  BATHROOM: { icon: Droplets, label: 'Bathroom', color: 'bg-cyan-100 text-cyan-600' },
  GARAGE: { icon: Car, label: 'Garage', color: 'bg-gray-200 text-gray-600' },
  BASEMENT: { icon: Building2, label: 'Basement', color: 'bg-stone-200 text-stone-600' },
  ATTIC: { icon: Home, label: 'Attic', color: 'bg-orange-100 text-orange-600' },
  LAUNDRY: { icon: Droplets, label: 'Laundry', color: 'bg-sky-100 text-sky-600' },
  OFFICE: { icon: FileText, label: 'Office', color: 'bg-green-100 text-green-600' },
  MUDROOM: { icon: Home, label: 'Mudroom', color: 'bg-brown-100 text-brown-600' },
  PANTRY: { icon: Refrigerator, label: 'Pantry', color: 'bg-yellow-100 text-yellow-600' },
  OUTDOOR_FRONT: { icon: Leaf, label: 'Front Yard', color: 'bg-emerald-100 text-emerald-600' },
  OUTDOOR_BACK: { icon: Leaf, label: 'Back Yard', color: 'bg-lime-100 text-lime-600' },
  POOL_AREA: { icon: Waves, label: 'Pool Area', color: 'bg-blue-200 text-blue-700' },
  MECHANICAL: { icon: Settings, label: 'Mechanical Room', color: 'bg-slate-200 text-slate-600' },
  OTHER: { icon: Home, label: 'Other', color: 'bg-gray-100 text-gray-500' },
};

const ASSET_CATEGORIES = {
  APPLIANCE: { icon: Refrigerator, label: 'Appliance' },
  HVAC: { icon: Flame, label: 'HVAC' },
  PLUMBING: { icon: Droplets, label: 'Plumbing' },
  ELECTRICAL: { icon: Zap, label: 'Electrical' },
  STRUCTURAL: { icon: Building2, label: 'Structural' },
  FURNITURE: { icon: Home, label: 'Furniture' },
  ELECTRONICS: { icon: Settings, label: 'Electronics' },
  OUTDOOR: { icon: Leaf, label: 'Outdoor' },
  VEHICLE: { icon: Car, label: 'Vehicle' },
  SAFETY: { icon: Wrench, label: 'Safety' },
  OTHER: { icon: Settings, label: 'Other' },
};

// ===========================================================================
// SMART SUGGESTIONS BASED ON PROPERTY DATA
// ===========================================================================

function generateZoneSuggestions(household: Household): Array<{ type: string; name: string; suggested: boolean }> {
  const suggestions: Array<{ type: string; name: string; suggested: boolean }> = [];
  const enrichment = household.enrichmentData as Record<string, any> || {};
  const profile = household.homeProfile;

  // Always suggest kitchen
  suggestions.push({ type: 'KITCHEN', name: 'Kitchen', suggested: true });

  // Bedrooms based on count
  const bedroomCount = profile?.bedrooms || enrichment?.bedrooms || 3;
  if (bedroomCount >= 1) {
    suggestions.push({ type: 'BEDROOM', name: 'Primary Bedroom', suggested: true });
  }
  if (bedroomCount >= 2) {
    for (let i = 2; i <= Math.min(bedroomCount, 5); i++) {
      suggestions.push({ type: 'BEDROOM', name: `Bedroom ${i}`, suggested: true });
    }
  }

  // Bathrooms based on count
  const bathroomCount = Math.ceil(profile?.bathrooms || enrichment?.bathrooms || 2);
  if (bathroomCount >= 1) {
    suggestions.push({ type: 'BATHROOM', name: 'Primary Bathroom', suggested: true });
  }
  if (bathroomCount >= 2) {
    for (let i = 2; i <= Math.min(bathroomCount, 4); i++) {
      suggestions.push({ type: 'BATHROOM', name: `Bathroom ${i}`, suggested: true });
    }
  }

  // Living areas
  suggestions.push({ type: 'LIVING_ROOM', name: 'Living Room', suggested: true });

  // Garage if detected
  if (enrichment?.garageType || enrichment?.garageCars) {
    suggestions.push({ type: 'GARAGE', name: 'Garage', suggested: true });
  }

  // Pool if detected
  if (enrichment?.hasPool) {
    suggestions.push({ type: 'POOL_AREA', name: 'Pool Area', suggested: true });
  }

  // Laundry
  suggestions.push({ type: 'LAUNDRY', name: 'Laundry Room', suggested: true });

  // Outdoor areas
  suggestions.push({ type: 'OUTDOOR_FRONT', name: 'Front Yard', suggested: true });
  suggestions.push({ type: 'OUTDOOR_BACK', name: 'Back Yard', suggested: true });

  // HVAC/Mechanical
  suggestions.push({ type: 'MECHANICAL', name: 'HVAC/Mechanical', suggested: true });

  return suggestions;
}

function generateAssetSuggestions(household: Household, zoneType: string): Array<{ name: string; category: string }> {
  const enrichment = household.enrichmentData as Record<string, any> || {};
  const suggestions: Array<{ name: string; category: string }> = [];

  switch (zoneType) {
    case 'KITCHEN':
      suggestions.push(
        { name: 'Refrigerator', category: 'APPLIANCE' },
        { name: 'Dishwasher', category: 'APPLIANCE' },
        { name: 'Oven/Range', category: 'APPLIANCE' },
        { name: 'Microwave', category: 'APPLIANCE' },
        { name: 'Garbage Disposal', category: 'PLUMBING' },
      );
      break;
    case 'LAUNDRY':
      suggestions.push(
        { name: 'Washer', category: 'APPLIANCE' },
        { name: 'Dryer', category: 'APPLIANCE' },
      );
      break;
    case 'GARAGE':
      suggestions.push(
        { name: 'Garage Door Opener', category: 'ELECTRICAL' },
        { name: 'Water Heater', category: 'PLUMBING' },
      );
      break;
    case 'MECHANICAL':
      suggestions.push(
        { name: 'Furnace', category: 'HVAC' },
        { name: 'Air Conditioner', category: 'HVAC' },
      );
      if (enrichment?.heatingType?.toLowerCase().includes('oil')) {
        suggestions.push({ name: 'Oil Tank', category: 'HVAC' });
      }
      break;
    case 'POOL_AREA':
      suggestions.push(
        { name: 'Pool Pump', category: 'OUTDOOR' },
        { name: 'Pool Heater', category: 'OUTDOOR' },
        { name: 'Pool Filter', category: 'OUTDOOR' },
      );
      break;
    case 'OUTDOOR_FRONT':
    case 'OUTDOOR_BACK':
      suggestions.push(
        { name: 'Sprinkler System', category: 'OUTDOOR' },
        { name: 'Outdoor Lighting', category: 'ELECTRICAL' },
      );
      break;
    default:
      break;
  }

  // Add fireplace if detected
  if (enrichment?.fireplaceCount && enrichment.fireplaceCount > 0 && zoneType === 'LIVING_ROOM') {
    suggestions.push({ name: 'Fireplace', category: 'HVAC' });
  }

  return suggestions;
}

// ===========================================================================
// MAIN COMPONENT
// ===========================================================================

export default function HouseholdProfileBuilder() {
  const params = useParams();
  const router = useRouter();
  const householdId = params.householdId as string;

  const [household, setHousehold] = useState<Household | null>(null);
  const [zones, setZones] = useState<Zone[]>([]);
  const [assets, setAssets] = useState<PropertyAsset[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedZone, setSelectedZone] = useState<Zone | null>(null);
  const [showAddZone, setShowAddZone] = useState(false);
  const [showAddAsset, setShowAddAsset] = useState(false);

  // Form state
  const [newZoneName, setNewZoneName] = useState('');
  const [newZoneType, setNewZoneType] = useState('KITCHEN');
  const [newZoneFloor, setNewZoneFloor] = useState('');

  const [newAssetName, setNewAssetName] = useState('');
  const [newAssetCategory, setNewAssetCategory] = useState('APPLIANCE');
  const [newAssetBrand, setNewAssetBrand] = useState('');
  const [newAssetModel, setNewAssetModel] = useState('');

  useEffect(() => {
    fetchData();
  }, [householdId]);

  const fetchData = async () => {
    setIsLoading(true);
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      // Fetch household details
      const householdRes = await fetch(`${apiUrl}/households/${householdId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (householdRes.ok) {
        const householdData = await householdRes.json();
        setHousehold(householdData);
      }

      // Fetch zones
      const zonesRes = await fetch(`${apiUrl}/households/${householdId}/zones`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (zonesRes.ok) {
        const zonesData = await zonesRes.json();
        setZones(zonesData);
      }

      // Fetch assets
      const assetsRes = await fetch(`${apiUrl}/households/${householdId}/assets`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (assetsRes.ok) {
        const assetsData = await assetsRes.json();
        setAssets(assetsData);
      }
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleAddZone = async () => {
    if (!newZoneName.trim()) return;

    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const res = await fetch(`${apiUrl}/households/${householdId}/zones`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          name: newZoneName,
          type: newZoneType,
          floor: newZoneFloor || undefined,
        }),
      });

      if (res.ok) {
        const zone = await res.json();
        setZones([...zones, zone]);
        setNewZoneName('');
        setNewZoneFloor('');
        setShowAddZone(false);
      }
    } catch (error) {
      console.error('Error adding zone:', error);
    }
  };

  const handleAddAsset = async () => {
    if (!newAssetName.trim() || !selectedZone) return;

    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const res = await fetch(`${apiUrl}/households/${householdId}/assets`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          name: newAssetName,
          category: newAssetCategory,
          brand: newAssetBrand || undefined,
          model: newAssetModel || undefined,
          zoneId: selectedZone.id,
        }),
      });

      if (res.ok) {
        const asset = await res.json();
        setAssets([...assets, asset]);
        setNewAssetName('');
        setNewAssetBrand('');
        setNewAssetModel('');
        setShowAddAsset(false);
        // Update zone asset count
        setZones(zones.map(z =>
          z.id === selectedZone.id ? { ...z, assetCount: (z.assetCount || 0) + 1 } : z
        ));
      }
    } catch (error) {
      console.error('Error adding asset:', error);
    }
  };

  const handleQuickAddZone = async (suggestion: { type: string; name: string }) => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const res = await fetch(`${apiUrl}/households/${householdId}/zones`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          name: suggestion.name,
          type: suggestion.type,
        }),
      });

      if (res.ok) {
        const zone = await res.json();
        setZones([...zones, zone]);
      }
    } catch (error) {
      console.error('Error adding zone:', error);
    }
  };

  const handleQuickAddAsset = async (suggestion: { name: string; category: string }) => {
    if (!selectedZone) return;

    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const res = await fetch(`${apiUrl}/households/${householdId}/assets`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          name: suggestion.name,
          category: suggestion.category,
          zoneId: selectedZone.id,
        }),
      });

      if (res.ok) {
        const asset = await res.json();
        setAssets([...assets, asset]);
        setZones(zones.map(z =>
          z.id === selectedZone.id ? { ...z, assetCount: (z.assetCount || 0) + 1 } : z
        ));
      }
    } catch (error) {
      console.error('Error adding asset:', error);
    }
  };

  // Get zone suggestions that haven't been added yet
  const zoneSuggestions = household
    ? generateZoneSuggestions(household).filter(
        s => !zones.some(z => z.name.toLowerCase() === s.name.toLowerCase())
      )
    : [];

  // Get asset suggestions for the selected zone
  const assetSuggestions = household && selectedZone
    ? generateAssetSuggestions(household, selectedZone.type).filter(
        s => !assets.some(a => a.zoneId === selectedZone.id && a.name.toLowerCase() === s.name.toLowerCase())
      )
    : [];

  // Get assets for selected zone
  const zoneAssets = selectedZone
    ? assets.filter(a => a.zoneId === selectedZone.id)
    : [];

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-haven-champagne-600 mx-auto mb-4" />
          <p className="text-gray-500">Loading home profile...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-20">
        <div className="max-w-6xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => router.push('/manager/onboarding')}
                className="p-2 hover:bg-gray-100 rounded-lg transition"
              >
                <ArrowLeft className="w-5 h-5 text-gray-600" />
              </button>
              <div>
                <h1 className="text-lg font-bold text-haven-navy-900">
                  {household?.name} - Home Profile
                </h1>
                <p className="text-sm text-gray-500">
                  {household?.homeProfile?.addressLine1}, {household?.homeProfile?.city}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-sm text-gray-500">
                {zones.length} zones • {assets.length} assets
              </span>
              {household?.owner?.phone && (
                <a
                  href={`tel:${household.owner.phone}`}
                  className="flex items-center gap-2 px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg text-sm transition"
                >
                  <Phone className="w-4 h-4" />
                  Call Owner
                </a>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 py-6">
        <div className="grid grid-cols-12 gap-6">
          {/* Left Sidebar - Zones List */}
          <div className="col-span-4">
            <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
              <div className="p-4 border-b border-gray-100">
                <div className="flex items-center justify-between">
                  <h2 className="font-semibold text-haven-navy-900">Zones</h2>
                  <button
                    onClick={() => setShowAddZone(true)}
                    className="p-1.5 hover:bg-gray-100 rounded-lg transition"
                  >
                    <Plus className="w-5 h-5 text-gray-600" />
                  </button>
                </div>
              </div>

              {/* Zone List */}
              <div className="divide-y divide-gray-100 max-h-[500px] overflow-y-auto">
                {zones.length === 0 ? (
                  <div className="p-6 text-center">
                    <Home className="w-10 h-10 text-gray-300 mx-auto mb-3" />
                    <p className="text-gray-500 text-sm mb-4">No zones added yet</p>
                    <button
                      onClick={() => setShowAddZone(true)}
                      className="text-sm text-haven-champagne-600 hover:text-haven-champagne-700 font-medium"
                    >
                      Add first zone
                    </button>
                  </div>
                ) : (
                  zones.map((zone) => {
                    const zoneInfo = ZONE_TYPES[zone.type as keyof typeof ZONE_TYPES] || ZONE_TYPES.OTHER;
                    const Icon = zoneInfo.icon;
                    return (
                      <button
                        key={zone.id}
                        onClick={() => setSelectedZone(zone)}
                        className={`w-full p-4 text-left hover:bg-gray-50 transition flex items-center justify-between ${
                          selectedZone?.id === zone.id ? 'bg-haven-champagne-50' : ''
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${zoneInfo.color}`}>
                            <Icon className="w-5 h-5" />
                          </div>
                          <div>
                            <p className="font-medium text-haven-navy-900">{zone.name}</p>
                            <p className="text-xs text-gray-500">
                              {zone.assetCount || 0} assets
                              {zone.floor && ` • ${zone.floor}`}
                            </p>
                          </div>
                        </div>
                        <ChevronRight className="w-4 h-4 text-gray-400" />
                      </button>
                    );
                  })
                )}
              </div>

              {/* Quick Add Suggestions */}
              {zoneSuggestions.length > 0 && (
                <div className="p-4 border-t border-gray-100 bg-gray-50">
                  <div className="flex items-center gap-2 mb-3">
                    <Sparkles className="w-4 h-4 text-haven-champagne-600" />
                    <span className="text-xs font-medium text-gray-600 uppercase tracking-wide">
                      Suggested Zones
                    </span>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {zoneSuggestions.slice(0, 6).map((suggestion) => (
                      <button
                        key={suggestion.name}
                        onClick={() => handleQuickAddZone(suggestion)}
                        className="px-3 py-1.5 bg-white border border-gray-200 rounded-full text-xs font-medium text-gray-700 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 transition"
                      >
                        + {suggestion.name}
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Right Panel - Zone Details / Assets */}
          <div className="col-span-8">
            {selectedZone ? (
              <div className="bg-white rounded-xl border border-gray-200">
                {/* Zone Header */}
                <div className="p-6 border-b border-gray-100">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-4">
                      <div className={`w-14 h-14 rounded-xl flex items-center justify-center ${
                        ZONE_TYPES[selectedZone.type as keyof typeof ZONE_TYPES]?.color || 'bg-gray-100'
                      }`}>
                        {(() => {
                          const Icon = ZONE_TYPES[selectedZone.type as keyof typeof ZONE_TYPES]?.icon || Home;
                          return <Icon className="w-7 h-7" />;
                        })()}
                      </div>
                      <div>
                        <h2 className="text-xl font-bold text-haven-navy-900">{selectedZone.name}</h2>
                        <p className="text-gray-500">
                          {selectedZone.floor || 'No floor specified'} • {zoneAssets.length} assets
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <button className="p-2 hover:bg-gray-100 rounded-lg transition">
                        <Camera className="w-5 h-5 text-gray-500" />
                      </button>
                      <button
                        onClick={() => setShowAddAsset(true)}
                        className="flex items-center gap-2 px-4 py-2 bg-haven-navy-900 text-white rounded-lg text-sm font-medium hover:bg-haven-navy-800 transition"
                      >
                        <Plus className="w-4 h-4" />
                        Add Asset
                      </button>
                    </div>
                  </div>
                </div>

                {/* Assets List */}
                <div className="p-6">
                  <h3 className="font-semibold text-haven-navy-900 mb-4">Assets in {selectedZone.name}</h3>

                  {zoneAssets.length === 0 ? (
                    <div className="text-center py-8">
                      <Wrench className="w-10 h-10 text-gray-300 mx-auto mb-3" />
                      <p className="text-gray-500 text-sm mb-4">No assets in this zone yet</p>
                      <button
                        onClick={() => setShowAddAsset(true)}
                        className="text-sm text-haven-champagne-600 hover:text-haven-champagne-700 font-medium"
                      >
                        Add first asset
                      </button>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {zoneAssets.map((asset) => {
                        const categoryInfo = ASSET_CATEGORIES[asset.category as keyof typeof ASSET_CATEGORIES] || ASSET_CATEGORIES.OTHER;
                        const Icon = categoryInfo.icon;
                        return (
                          <div
                            key={asset.id}
                            className="p-4 border border-gray-200 rounded-xl hover:border-gray-300 transition"
                          >
                            <div className="flex items-start justify-between">
                              <div className="flex items-center gap-3">
                                <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
                                  <Icon className="w-5 h-5 text-gray-600" />
                                </div>
                                <div>
                                  <p className="font-medium text-haven-navy-900">{asset.name}</p>
                                  <p className="text-xs text-gray-500">
                                    {categoryInfo.label}
                                    {asset.brand && ` • ${asset.brand}`}
                                    {asset.model && ` ${asset.model}`}
                                  </p>
                                </div>
                              </div>
                              <div className="flex items-center gap-2">
                                {asset.condition && (
                                  <span className={`px-2 py-1 text-xs rounded-full ${
                                    asset.condition === 'Excellent' ? 'bg-emerald-100 text-emerald-700' :
                                    asset.condition === 'Good' ? 'bg-blue-100 text-blue-700' :
                                    asset.condition === 'Fair' ? 'bg-amber-100 text-amber-700' :
                                    'bg-red-100 text-red-700'
                                  }`}>
                                    {asset.condition}
                                  </span>
                                )}
                                <button className="p-1.5 hover:bg-gray-100 rounded transition">
                                  <ChevronRight className="w-4 h-4 text-gray-400" />
                                </button>
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}

                  {/* Quick Add Asset Suggestions */}
                  {assetSuggestions.length > 0 && (
                    <div className="mt-6 pt-6 border-t border-gray-100">
                      <div className="flex items-center gap-2 mb-3">
                        <Sparkles className="w-4 h-4 text-haven-champagne-600" />
                        <span className="text-xs font-medium text-gray-600 uppercase tracking-wide">
                          Suggested Assets for {selectedZone.name}
                        </span>
                      </div>
                      <div className="flex flex-wrap gap-2">
                        {assetSuggestions.map((suggestion) => (
                          <button
                            key={suggestion.name}
                            onClick={() => handleQuickAddAsset(suggestion)}
                            className="px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-full text-xs font-medium text-gray-700 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 transition"
                          >
                            + {suggestion.name}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            ) : (
              <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
                <Home className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-600 mb-2">
                  Select a zone to view details
                </h3>
                <p className="text-sm text-gray-400 mb-6">
                  Or add zones using the suggestions below
                </p>
                {zoneSuggestions.length > 0 && (
                  <div className="flex flex-wrap justify-center gap-2">
                    {zoneSuggestions.slice(0, 4).map((suggestion) => (
                      <button
                        key={suggestion.name}
                        onClick={() => handleQuickAddZone(suggestion)}
                        className="px-4 py-2 bg-haven-champagne-100 text-haven-champagne-700 rounded-lg text-sm font-medium hover:bg-haven-champagne-200 transition"
                      >
                        + Add {suggestion.name}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Add Zone Modal */}
      {showAddZone && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6">
            <h2 className="text-xl font-bold text-haven-navy-900 mb-6">Add Zone</h2>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Zone Name</label>
                <input
                  type="text"
                  value={newZoneName}
                  onChange={(e) => setNewZoneName(e.target.value)}
                  placeholder="e.g., Primary Bedroom"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Zone Type</label>
                <select
                  value={newZoneType}
                  onChange={(e) => setNewZoneType(e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                >
                  {Object.entries(ZONE_TYPES).map(([key, value]) => (
                    <option key={key} value={key}>{value.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Floor (optional)</label>
                <input
                  type="text"
                  value={newZoneFloor}
                  onChange={(e) => setNewZoneFloor(e.target.value)}
                  placeholder="e.g., 2nd Floor"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                />
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setShowAddZone(false)}
                className="flex-1 px-4 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              <button
                onClick={handleAddZone}
                disabled={!newZoneName.trim()}
                className="flex-1 px-4 py-2.5 bg-haven-navy-900 text-white rounded-xl font-medium hover:bg-haven-navy-800 transition disabled:opacity-50"
              >
                Add Zone
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Asset Modal */}
      {showAddAsset && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6">
            <h2 className="text-xl font-bold text-haven-navy-900 mb-6">
              Add Asset to {selectedZone?.name}
            </h2>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Asset Name</label>
                <input
                  type="text"
                  value={newAssetName}
                  onChange={(e) => setNewAssetName(e.target.value)}
                  placeholder="e.g., Refrigerator"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Category</label>
                <select
                  value={newAssetCategory}
                  onChange={(e) => setNewAssetCategory(e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                >
                  {Object.entries(ASSET_CATEGORIES).map(([key, value]) => (
                    <option key={key} value={key}>{value.label}</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Brand (optional)</label>
                  <input
                    type="text"
                    value={newAssetBrand}
                    onChange={(e) => setNewAssetBrand(e.target.value)}
                    placeholder="e.g., Samsung"
                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Model (optional)</label>
                  <input
                    type="text"
                    value={newAssetModel}
                    onChange={(e) => setNewAssetModel(e.target.value)}
                    placeholder="e.g., RF28R7351"
                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                  />
                </div>
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setShowAddAsset(false)}
                className="flex-1 px-4 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              <button
                onClick={handleAddAsset}
                disabled={!newAssetName.trim()}
                className="flex-1 px-4 py-2.5 bg-haven-navy-900 text-white rounded-xl font-medium hover:bg-haven-navy-800 transition disabled:opacity-50"
              >
                Add Asset
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
