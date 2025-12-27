'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { Card, Badge, Button } from '@/components/ui';
import {
  ArrowLeft,
  Package,
  Wrench,
  Calendar,
  Phone,
  AlertCircle,
  CheckCircle2,
  Clock,
  Info,
  ChevronRight,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface ZoneData {
  id: string;
  name: string;
  type: string;
  floor: string | null;
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
}

// ============================================================================
// HELPERS
// ============================================================================

function formatDate(dateString: string | null) {
  if (!dateString) return null;
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

function getConditionColor(condition: string | null) {
  switch (condition) {
    case 'Excellent':
    case 'Good':
      return 'bg-green-100 text-green-700';
    case 'Fair':
      return 'bg-yellow-100 text-yellow-700';
    case 'Poor':
    case 'Needs Replacement':
      return 'bg-red-100 text-red-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
}

function isOverdue(dateString: string | null) {
  if (!dateString) return false;
  return new Date(dateString) < new Date();
}

// ============================================================================
// COMPONENTS
// ============================================================================

function PageSkeleton() {
  return (
    <div className="pb-32 lg:pb-8 max-w-4xl mx-auto animate-pulse">
      <div className="h-8 bg-gray-200 rounded w-32 mb-6" />
      <div className="h-24 bg-gray-200 rounded-xl mb-6" />
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-32 bg-gray-200 rounded-xl" />
        ))}
      </div>
    </div>
  );
}

function AssetCard({ asset }: { asset: ZoneData['assets'][0] }) {
  const overdue = isOverdue(asset.nextServiceDate);

  return (
    <Card hover>
      <div className="flex items-start justify-between mb-3">
        <div>
          <h3 className="font-semibold text-gray-900">{asset.name}</h3>
          <p className="text-sm text-gray-500">{asset.category}</p>
        </div>
        {asset.condition && (
          <Badge className={getConditionColor(asset.condition)}>{asset.condition}</Badge>
        )}
      </div>

      {/* Brand/Model */}
      {(asset.brand || asset.model) && (
        <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
          <Info className="w-4 h-4" />
          {[asset.brand, asset.model].filter(Boolean).join(' ')}
        </div>
      )}

      {/* Serial Number */}
      {asset.serialNumber && (
        <p className="text-xs text-gray-400 mb-3">S/N: {asset.serialNumber}</p>
      )}

      {/* Service Info */}
      <div className="grid grid-cols-2 gap-4 pt-3 border-t border-gray-100">
        <div>
          <p className="text-xs text-gray-500 mb-1">Last Service</p>
          <p className="text-sm font-medium text-gray-700">
            {asset.lastServiceDate ? formatDate(asset.lastServiceDate) : 'Not recorded'}
          </p>
        </div>
        <div>
          <p className="text-xs text-gray-500 mb-1">Next Service</p>
          <div className="flex items-center gap-1">
            {overdue && <AlertCircle className="w-4 h-4 text-red-500" />}
            <p className={`text-sm font-medium ${overdue ? 'text-red-600' : 'text-gray-700'}`}>
              {asset.nextServiceDate ? formatDate(asset.nextServiceDate) : 'Not scheduled'}
            </p>
          </div>
        </div>
      </div>

      {/* Service Vendor */}
      {asset.serviceVendor && (
        <div className="flex items-center gap-2 mt-3 pt-3 border-t border-gray-100">
          <Phone className="w-4 h-4 text-gray-400" />
          <span className="text-sm text-gray-600">{asset.serviceVendor}</span>
        </div>
      )}

      {/* Notes */}
      {asset.notes && (
        <div className="mt-3 pt-3 border-t border-gray-100">
          <p className="text-sm text-gray-600">{asset.notes}</p>
        </div>
      )}
    </Card>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function ZoneDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { getIdToken } = useAuth();
  const [data, setData] = useState<ZoneData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const zoneId = params.zoneId as string;

  useEffect(() => {
    if (zoneId) {
      fetchZone();
    }
  }, [zoneId]);

  const fetchZone = async () => {
    try {
      const token = await getIdToken();
      if (!token) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/property/zones/${zoneId}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to load zone');
      }

      const result = await response.json();
      setData(result);
    } catch (err) {
      console.error('Zone error:', err);
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
        <p className="text-red-600 mb-4">Error loading zone: {error}</p>
        <Button onClick={fetchZone}>Try Again</Button>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="p-6 text-center">
        <Package className="w-12 h-12 text-gray-300 mx-auto mb-4" />
        <p className="text-gray-500">Zone not found</p>
      </div>
    );
  }

  const overdueAssets = data.assets.filter((a) => isOverdue(a.nextServiceDate));

  return (
    <div className="pb-32 lg:pb-8 max-w-4xl mx-auto">
      {/* Back Button */}
      <button
        onClick={() => router.back()}
        className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-6"
      >
        <ArrowLeft className="w-5 h-5" />
        Back to Home
      </button>

      {/* Zone Header */}
      <div className="bg-gradient-to-br from-haven-700 to-haven-800 rounded-2xl p-6 text-white mb-6">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold mb-1">{data.name}</h1>
            {data.floor && <p className="text-haven-100">{data.floor}</p>}
          </div>
          <Badge variant="secondary" className="bg-white/20 text-white border-0">
            {data.type}
          </Badge>
        </div>

        <div className="grid grid-cols-2 gap-4 mt-6">
          <div className="bg-white/10 rounded-xl px-4 py-3">
            <div className="flex items-center gap-2 text-haven-100 text-sm mb-1">
              <Package className="w-4 h-4" />
              Assets
            </div>
            <p className="text-xl font-bold">{data.assets.length}</p>
          </div>
          {overdueAssets.length > 0 && (
            <div className="bg-red-500/20 rounded-xl px-4 py-3">
              <div className="flex items-center gap-2 text-red-100 text-sm mb-1">
                <AlertCircle className="w-4 h-4" />
                Overdue
              </div>
              <p className="text-xl font-bold">{overdueAssets.length}</p>
            </div>
          )}
        </div>
      </div>

      {/* Notes */}
      {data.notes && (
        <Card className="mb-6">
          <h2 className="font-semibold text-gray-900 mb-2">Notes</h2>
          <p className="text-gray-600">{data.notes}</p>
        </Card>
      )}

      {/* Procedures */}
      {data.procedures && (
        <Card className="mb-6">
          <h2 className="font-semibold text-gray-900 mb-2">Procedures</h2>
          <p className="text-gray-600 whitespace-pre-wrap">{data.procedures}</p>
        </Card>
      )}

      {/* Assets */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900">
            Assets ({data.assets.length})
          </h2>
          <Button variant="outline" size="sm">
            Add Asset
          </Button>
        </div>

        {data.assets.length === 0 ? (
          <Card>
            <div className="py-12 text-center">
              <Package className="w-12 h-12 text-gray-300 mx-auto mb-4" />
              <p className="text-gray-500 mb-2">No assets in this zone</p>
              <Button variant="outline" size="sm">
                Add First Asset
              </Button>
            </div>
          </Card>
        ) : (
          <div className="space-y-4">
            {data.assets.map((asset) => (
              <AssetCard key={asset.id} asset={asset} />
            ))}
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-2 gap-3">
        <Link href="/app/requests">
          <Card hover className="text-center py-4">
            <Wrench className="w-6 h-6 mx-auto mb-2 text-haven-champagne-600" />
            <p className="text-sm font-medium text-gray-700">Request Service</p>
          </Card>
        </Link>
        <Link href="/app/maintenance">
          <Card hover className="text-center py-4">
            <Calendar className="w-6 h-6 mx-auto mb-2 text-haven-champagne-600" />
            <p className="text-sm font-medium text-gray-700">Schedule Maintenance</p>
          </Card>
        </Link>
      </div>
    </div>
  );
}
