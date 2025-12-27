'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Home,
  ChevronRight,
  Loader2,
  Wrench,
  MapPin,
  Refrigerator,
  Flame,
  Droplets,
  Zap,
  Car,
  Leaf,
  Waves,
  Settings,
  FileText,
  Phone,
  Calendar,
  Clock,
  CheckCircle,
  AlertCircle,
  Building2,
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
  serialNumber?: string;
  condition?: string;
  zoneId?: string;
  zoneName?: string;
  serviceVendorId?: string;
  serviceVendorName?: string;
  lastServiceDate?: string;
  nextServiceDate?: string;
  photos: string[];
  notes?: string;
}

// ===========================================================================
// ZONE TYPE ICONS AND LABELS
// ===========================================================================

const ZONE_TYPES: Record<string, { icon: React.ElementType; label: string; color: string }> = {
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
  MUDROOM: { icon: Home, label: 'Mudroom', color: 'bg-amber-100 text-amber-600' },
  PANTRY: { icon: Refrigerator, label: 'Pantry', color: 'bg-yellow-100 text-yellow-600' },
  OUTDOOR_FRONT: { icon: Leaf, label: 'Front Yard', color: 'bg-emerald-100 text-emerald-600' },
  OUTDOOR_BACK: { icon: Leaf, label: 'Back Yard', color: 'bg-lime-100 text-lime-600' },
  POOL_AREA: { icon: Waves, label: 'Pool Area', color: 'bg-blue-200 text-blue-700' },
  MECHANICAL: { icon: Settings, label: 'Mechanical Room', color: 'bg-slate-200 text-slate-600' },
  OTHER: { icon: Home, label: 'Other', color: 'bg-gray-100 text-gray-500' },
};

const ASSET_CATEGORIES: Record<string, { icon: React.ElementType; label: string }> = {
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
// MAIN COMPONENT
// ===========================================================================

export default function YourHomeZonesPage() {
  const router = useRouter();
  const [zones, setZones] = useState<Zone[]>([]);
  const [assets, setAssets] = useState<PropertyAsset[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedZone, setSelectedZone] = useState<Zone | null>(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setIsLoading(true);
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      // Get user's household first
      const meRes = await fetch(`${apiUrl}/users/me`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!meRes.ok) return;
      const me = await meRes.json();
      const householdId = me.ownedHouseholds?.[0]?.id;
      if (!householdId) return;

      // Fetch zones
      const zonesRes = await fetch(`${apiUrl}/households/${householdId}/zones`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (zonesRes.ok) {
        const zonesData = await zonesRes.json();
        setZones(zonesData);
        if (zonesData.length > 0) {
          setSelectedZone(zonesData[0]);
        }
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

  // Get assets for selected zone
  const zoneAssets = selectedZone
    ? assets.filter(a => a.zoneId === selectedZone.id)
    : [];

  // Get service status for an asset
  const getServiceStatus = (asset: PropertyAsset) => {
    if (!asset.nextServiceDate) return null;
    const nextDate = new Date(asset.nextServiceDate);
    const now = new Date();
    const daysUntil = Math.ceil((nextDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));

    if (daysUntil < 0) return { status: 'overdue', label: 'Service overdue', color: 'text-red-600 bg-red-50' };
    if (daysUntil <= 30) return { status: 'soon', label: 'Service soon', color: 'text-amber-600 bg-amber-50' };
    return { status: 'ok', label: 'Up to date', color: 'text-emerald-600 bg-emerald-50' };
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-haven-champagne-600 mx-auto mb-4" />
          <p className="text-gray-500">Loading your home...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-6xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-xl font-bold text-haven-navy-900">Your Home</h1>
              <p className="text-sm text-gray-500">
                {zones.length} zones • {assets.length} assets
              </p>
            </div>
            <button
              onClick={() => router.push('/app/home')}
              className="text-sm text-haven-champagne-600 hover:text-haven-champagne-700 font-medium"
            >
              View Full Profile
            </button>
          </div>
        </div>
      </div>

      {zones.length === 0 ? (
        // Empty State
        <div className="max-w-2xl mx-auto px-4 py-16 text-center">
          <div className="w-20 h-20 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-6">
            <Home className="w-10 h-10 text-haven-champagne-600" />
          </div>
          <h2 className="text-2xl font-bold text-haven-navy-900 mb-3">
            Your home profile is being built
          </h2>
          <p className="text-gray-500 mb-8 max-w-md mx-auto">
            Your Home Manager is creating a comprehensive profile of your home.
            Once complete, you&apos;ll see all your zones, appliances, and systems here.
          </p>
          <div className="bg-white rounded-xl border border-gray-200 p-6 text-left max-w-md mx-auto">
            <h3 className="font-semibold text-haven-navy-900 mb-4">What to expect:</h3>
            <ul className="space-y-3 text-sm text-gray-600">
              <li className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-emerald-500 mt-0.5 flex-shrink-0" />
                <span>Room-by-room organization of your home</span>
              </li>
              <li className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-emerald-500 mt-0.5 flex-shrink-0" />
                <span>All appliances and systems tracked</span>
              </li>
              <li className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-emerald-500 mt-0.5 flex-shrink-0" />
                <span>Service history and maintenance schedules</span>
              </li>
              <li className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-emerald-500 mt-0.5 flex-shrink-0" />
                <span>Connected vendors for each system</span>
              </li>
            </ul>
          </div>
        </div>
      ) : (
        <div className="max-w-6xl mx-auto px-4 py-6">
          <div className="grid grid-cols-12 gap-6">
            {/* Left Sidebar - Zones List */}
            <div className="col-span-4">
              <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
                <div className="p-4 border-b border-gray-100">
                  <h2 className="font-semibold text-haven-navy-900">Zones</h2>
                </div>

                <div className="divide-y divide-gray-100 max-h-[600px] overflow-y-auto">
                  {zones.map((zone) => {
                    const zoneInfo = ZONE_TYPES[zone.type] || ZONE_TYPES.OTHER;
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
                              {zone.assetCount || 0} items
                              {zone.floor && ` • ${zone.floor}`}
                            </p>
                          </div>
                        </div>
                        <ChevronRight className="w-4 h-4 text-gray-400" />
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Right Panel - Zone Details / Assets */}
            <div className="col-span-8">
              {selectedZone ? (
                <div className="bg-white rounded-xl border border-gray-200">
                  {/* Zone Header */}
                  <div className="p-6 border-b border-gray-100">
                    <div className="flex items-start gap-4">
                      <div className={`w-14 h-14 rounded-xl flex items-center justify-center ${
                        ZONE_TYPES[selectedZone.type]?.color || 'bg-gray-100'
                      }`}>
                        {(() => {
                          const Icon = ZONE_TYPES[selectedZone.type]?.icon || Home;
                          return <Icon className="w-7 h-7" />;
                        })()}
                      </div>
                      <div>
                        <h2 className="text-xl font-bold text-haven-navy-900">{selectedZone.name}</h2>
                        <p className="text-gray-500">
                          {selectedZone.floor || 'No floor specified'} • {zoneAssets.length} items
                        </p>
                        {selectedZone.notes && (
                          <p className="text-sm text-gray-600 mt-2">{selectedZone.notes}</p>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Assets List */}
                  <div className="p-6">
                    <h3 className="font-semibold text-haven-navy-900 mb-4">Items in {selectedZone.name}</h3>

                    {zoneAssets.length === 0 ? (
                      <div className="text-center py-8">
                        <Wrench className="w-10 h-10 text-gray-300 mx-auto mb-3" />
                        <p className="text-gray-500 text-sm">No items in this zone yet</p>
                      </div>
                    ) : (
                      <div className="space-y-3">
                        {zoneAssets.map((asset) => {
                          const categoryInfo = ASSET_CATEGORIES[asset.category] || ASSET_CATEGORIES.OTHER;
                          const Icon = categoryInfo.icon;
                          const serviceStatus = getServiceStatus(asset);

                          return (
                            <div
                              key={asset.id}
                              className="p-4 border border-gray-200 rounded-xl hover:border-gray-300 transition"
                            >
                              <div className="flex items-start justify-between">
                                <div className="flex items-start gap-3">
                                  <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0">
                                    <Icon className="w-5 h-5 text-gray-600" />
                                  </div>
                                  <div>
                                    <p className="font-medium text-haven-navy-900">{asset.name}</p>
                                    <p className="text-sm text-gray-500">
                                      {categoryInfo.label}
                                      {asset.brand && ` • ${asset.brand}`}
                                      {asset.model && ` ${asset.model}`}
                                    </p>
                                    {asset.serviceVendorName && (
                                      <p className="text-xs text-gray-500 mt-1 flex items-center gap-1">
                                        <Phone className="w-3 h-3" />
                                        Serviced by {asset.serviceVendorName}
                                      </p>
                                    )}
                                  </div>
                                </div>
                                <div className="flex flex-col items-end gap-2">
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
                                  {serviceStatus && (
                                    <span className={`px-2 py-1 text-xs rounded-full flex items-center gap-1 ${serviceStatus.color}`}>
                                      {serviceStatus.status === 'overdue' && <AlertCircle className="w-3 h-3" />}
                                      {serviceStatus.status === 'soon' && <Clock className="w-3 h-3" />}
                                      {serviceStatus.status === 'ok' && <CheckCircle className="w-3 h-3" />}
                                      {serviceStatus.label}
                                    </span>
                                  )}
                                </div>
                              </div>

                              {/* Service dates */}
                              {(asset.lastServiceDate || asset.nextServiceDate) && (
                                <div className="mt-3 pt-3 border-t border-gray-100 flex items-center gap-4 text-xs text-gray-500">
                                  {asset.lastServiceDate && (
                                    <span className="flex items-center gap-1">
                                      <Calendar className="w-3 h-3" />
                                      Last service: {new Date(asset.lastServiceDate).toLocaleDateString()}
                                    </span>
                                  )}
                                  {asset.nextServiceDate && (
                                    <span className="flex items-center gap-1">
                                      <Clock className="w-3 h-3" />
                                      Next service: {new Date(asset.nextServiceDate).toLocaleDateString()}
                                    </span>
                                  )}
                                </div>
                              )}
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>

                  {/* Zone Procedures */}
                  {selectedZone.procedures && (
                    <div className="p-6 border-t border-gray-100 bg-gray-50">
                      <h3 className="font-semibold text-haven-navy-900 mb-3">Care Instructions</h3>
                      <p className="text-sm text-gray-600 whitespace-pre-wrap">{selectedZone.procedures}</p>
                    </div>
                  )}
                </div>
              ) : (
                <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
                  <Home className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-600">
                    Select a zone to view details
                  </h3>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
