'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { Card, Badge, Button } from '@/components/ui';
import { getHealthColors } from '@/lib/utils/healthColors';
import {
  Home,
  MapPin,
  Bed,
  Bath,
  Square,
  Calendar,
  Wrench,
  ThermometerSun,
  Droplets,
  Zap,
  Waves,
  ChevronRight,
  AlertCircle,
  CheckCircle2,
  Clock,
  Loader2,
  Package,
  Plus,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface PropertyData {
  property: {
    id: string;
    name: string;
    address: {
      street: string;
      city: string;
      state: string;
      zip: string;
      full: string;
    } | null;
    details: {
      bedrooms: number | null;
      bathrooms: number | null;
      squareFeet: number | null;
      yearBuilt: number | null;
      lotSize: number | null;
      propertyType: string | null;
    };
    enrichment: Record<string, any> | null;
  };
  systems: Array<{
    id: string;
    name: string;
    category: string;
    status: 'good' | 'warning' | 'attention';
    warning?: string;
  }>;
  zones: Array<{
    id: string;
    name: string;
    type: string;
    floor: string | null;
    assetCount: number;
    photos: string[];
    notes: string | null;
    procedures: string | null;
    assets: Array<{
      id: string;
      name: string;
      category: string;
      brand: string | null;
      model: string | null;
      serialNumber: string | null;
      condition: string | null;
      lastServiceDate: string | null;
      nextServiceDate: string | null;
      serviceVendor: string | null;
      notes: string | null;
    }>;
  }>;
}

// ============================================================================
// HELPER COMPONENTS
// ============================================================================

function PageSkeleton() {
  return (
    <div className="pb-32 lg:pb-8 max-w-6xl mx-auto animate-pulse">
      <div className="h-48 bg-gray-200 rounded-2xl mb-6" />
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-32 bg-gray-200 rounded-xl" />
        ))}
      </div>
      <div className="h-64 bg-gray-200 rounded-xl" />
    </div>
  );
}

function getSystemIcon(category: string) {
  switch (category.toUpperCase()) {
    case 'HVAC':
      return <ThermometerSun className="w-5 h-5" />;
    case 'PLUMBING':
      return <Droplets className="w-5 h-5" />;
    case 'ELECTRICAL':
      return <Zap className="w-5 h-5" />;
    case 'POOL':
      return <Waves className="w-5 h-5" />;
    default:
      return <Wrench className="w-5 h-5" />;
  }
}

function getStatusColors(status: 'good' | 'warning' | 'attention') {
  switch (status) {
    case 'good':
      return {
        bg: 'bg-green-100',
        text: 'text-green-700',
        icon: <CheckCircle2 className="w-4 h-4 text-green-600" />,
      };
    case 'warning':
      return {
        bg: 'bg-yellow-100',
        text: 'text-yellow-700',
        icon: <Clock className="w-4 h-4 text-yellow-600" />,
      };
    case 'attention':
      return {
        bg: 'bg-red-100',
        text: 'text-red-700',
        icon: <AlertCircle className="w-4 h-4 text-red-600" />,
      };
  }
}

function formatDate(dateString: string | null) {
  if (!dateString) return null;
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

// ============================================================================
// PAGE COMPONENTS
// ============================================================================

function PropertyHeader({ property }: { property: PropertyData['property'] }) {
  return (
    <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-haven-700 via-haven-700 to-haven-800 p-6 text-white mb-6">
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 right-0 w-64 h-64 bg-white rounded-full -translate-y-1/2 translate-x-1/2" />
      </div>
      <div className="relative">
        <div className="flex items-start gap-4">
          <div className="w-14 h-14 bg-white/20 rounded-xl flex items-center justify-center">
            <Home className="w-7 h-7" />
          </div>
          <div className="flex-1">
            <h1 className="text-2xl font-bold mb-1">{property.name || 'Your Home'}</h1>
            {property.address && (
              <p className="text-haven-100 flex items-center gap-1">
                <MapPin className="w-4 h-4" />
                {property.address.full}
              </p>
            )}
          </div>
        </div>

        {/* Property Details */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-6">
          {property.details.bedrooms && (
            <div className="bg-white/10 rounded-xl px-4 py-3">
              <div className="flex items-center gap-2 text-haven-100 text-sm mb-1">
                <Bed className="w-4 h-4" />
                Bedrooms
              </div>
              <p className="text-xl font-bold">{property.details.bedrooms}</p>
            </div>
          )}
          {property.details.bathrooms && (
            <div className="bg-white/10 rounded-xl px-4 py-3">
              <div className="flex items-center gap-2 text-haven-100 text-sm mb-1">
                <Bath className="w-4 h-4" />
                Bathrooms
              </div>
              <p className="text-xl font-bold">{property.details.bathrooms}</p>
            </div>
          )}
          {property.details.squareFeet && (
            <div className="bg-white/10 rounded-xl px-4 py-3">
              <div className="flex items-center gap-2 text-haven-100 text-sm mb-1">
                <Square className="w-4 h-4" />
                Sq Ft
              </div>
              <p className="text-xl font-bold">{property.details.squareFeet.toLocaleString()}</p>
            </div>
          )}
          {property.details.yearBuilt && (
            <div className="bg-white/10 rounded-xl px-4 py-3">
              <div className="flex items-center gap-2 text-haven-100 text-sm mb-1">
                <Calendar className="w-4 h-4" />
                Year Built
              </div>
              <p className="text-xl font-bold">{property.details.yearBuilt}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function SystemsSection({ systems }: { systems: PropertyData['systems'] }) {
  if (systems.length === 0) return null;

  return (
    <div className="mb-6">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-gray-900">Home Systems</h2>
        <Link href="/app/home/systems" className="text-sm text-haven-champagne-600 hover:underline">
          View all
        </Link>
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
        {systems.map((system) => {
          const colors = getStatusColors(system.status);
          return (
            <div
              key={system.id}
              className={`${colors.bg} rounded-xl p-4 hover:shadow-md transition cursor-pointer`}
            >
              <div className="flex items-center justify-between mb-2">
                <div className={colors.text}>{getSystemIcon(system.category)}</div>
                {colors.icon}
              </div>
              <p className={`font-medium ${colors.text}`}>{system.name}</p>
              {system.warning && (
                <p className="text-xs text-gray-500 mt-1">{system.warning}</p>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

function ZonesSection({ zones }: { zones: PropertyData['zones'] }) {
  return (
    <div className="mb-6">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-gray-900">
          Zones ({zones.length})
        </h2>
        <Button variant="outline" size="sm" leftIcon={<Plus className="w-4 h-4" />}>
          Add Zone
        </Button>
      </div>

      {zones.length === 0 ? (
        <Card>
          <div className="py-12 text-center">
            <Package className="w-12 h-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 mb-2">No zones set up yet</p>
            <p className="text-sm text-gray-400">
              Your Home Manager will set up zones during onboarding
            </p>
          </div>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {zones.map((zone) => (
            <Link key={zone.id} href={`/app/home/zones/${zone.id}`}>
              <Card hover className="h-full">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h3 className="font-semibold text-gray-900">{zone.name}</h3>
                    {zone.floor && (
                      <p className="text-sm text-gray-500">{zone.floor}</p>
                    )}
                  </div>
                  <Badge variant="secondary">{zone.type}</Badge>
                </div>

                <div className="flex items-center gap-2 text-sm text-gray-600 mb-3">
                  <Package className="w-4 h-4" />
                  {zone.assetCount} asset{zone.assetCount !== 1 ? 's' : ''}
                </div>

                {zone.assets.slice(0, 3).map((asset) => (
                  <div
                    key={asset.id}
                    className="flex items-center justify-between py-2 border-t border-gray-100 text-sm"
                  >
                    <span className="text-gray-700">{asset.name}</span>
                    {asset.condition && (
                      <span
                        className={`text-xs px-2 py-0.5 rounded ${
                          asset.condition === 'Excellent' || asset.condition === 'Good'
                            ? 'bg-green-100 text-green-700'
                            : asset.condition === 'Fair'
                              ? 'bg-yellow-100 text-yellow-700'
                              : 'bg-red-100 text-red-700'
                        }`}
                      >
                        {asset.condition}
                      </span>
                    )}
                  </div>
                ))}

                {zone.assetCount > 3 && (
                  <p className="text-sm text-haven-champagne-600 pt-2 border-t border-gray-100">
                    +{zone.assetCount - 3} more
                  </p>
                )}

                <div className="flex items-center text-haven-champagne-600 text-sm mt-3 pt-3 border-t border-gray-100">
                  View details
                  <ChevronRight className="w-4 h-4 ml-1" />
                </div>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function YourHomePage() {
  const { getIdToken, householdId } = useAuth();
  const [data, setData] = useState<PropertyData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (householdId) {
      fetchProperty();
    }
  }, [householdId]);

  const fetchProperty = async () => {
    try {
      const token = await getIdToken();
      if (!token || !householdId) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/property/household/${householdId}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to load property');
      }

      const result = await response.json();
      setData(result);
    } catch (err) {
      console.error('Property error:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <PageSkeleton />;

  if (error) {
    return (
      <div className="p-6 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
        <p className="text-red-600 mb-4">Error loading property: {error}</p>
        <Button onClick={fetchProperty}>Try Again</Button>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="p-6 text-center">
        <Home className="w-12 h-12 text-gray-300 mx-auto mb-4" />
        <p className="text-gray-500 mb-2">No property data available yet</p>
        <p className="text-sm text-gray-400">
          Your Home Manager will set up your property during onboarding.
        </p>
      </div>
    );
  }

  return (
    <div className="pb-32 lg:pb-8 max-w-6xl mx-auto">
      <PropertyHeader property={data.property} />
      <SystemsSection systems={data.systems} />
      <ZonesSection zones={data.zones} />

      {/* Quick Actions */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <Link href="/app/home/systems">
          <Card hover className="text-center py-4">
            <ThermometerSun className="w-6 h-6 mx-auto mb-2 text-haven-champagne-600" />
            <p className="text-sm font-medium text-gray-700">Systems</p>
          </Card>
        </Link>
        <Link href="/app/maintenance">
          <Card hover className="text-center py-4">
            <Wrench className="w-6 h-6 mx-auto mb-2 text-haven-champagne-600" />
            <p className="text-sm font-medium text-gray-700">Maintenance</p>
          </Card>
        </Link>
        <Link href="/app/requests">
          <Card hover className="text-center py-4">
            <Plus className="w-6 h-6 mx-auto mb-2 text-haven-champagne-600" />
            <p className="text-sm font-medium text-gray-700">New Request</p>
          </Card>
        </Link>
        <Link href="/app/home/setup">
          <Card hover className="text-center py-4">
            <Package className="w-6 h-6 mx-auto mb-2 text-haven-champagne-600" />
            <p className="text-sm font-medium text-gray-700">Add Assets</p>
          </Card>
        </Link>
      </div>
    </div>
  );
}
