'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import {
  Search,
  ChevronRight,
  Home,
} from 'lucide-react';

interface Household {
  id: string;
  name: string;
  tier: string;
  status: string;
  address: string | null;
  primaryContact: { name: string; email: string } | null;
  homeManager: string;
  onboardingStatus: string | null;
  billCount: number;
  memberCount: number;
  monthlyFunding: number;
  createdAt: string;
}

const tierColors: Record<string, string> = {
  ESSENTIALS: 'bg-gray-100 text-gray-700',
  LITE: 'bg-blue-100 text-blue-700',
  HAVEN: 'bg-haven-100 text-haven-700',
  'HAVEN+': 'bg-purple-100 text-purple-700',
  ESTATE: 'bg-amber-100 text-amber-700',
};

const statusColors: Record<string, string> = {
  ACTIVE: 'bg-green-100 text-green-700',
  PENDING: 'bg-yellow-100 text-yellow-700',
  INACTIVE: 'bg-gray-100 text-gray-700',
  CANCELLED: 'bg-red-100 text-red-700',
};

export default function AdminHouseholdsPage() {
  const { getIdToken } = useAuth();
  const [data, setData] = useState<{ households: Household[]; pagination: any } | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [tierFilter, setTierFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  useEffect(() => {
    fetchHouseholds();
  }, [tierFilter, statusFilter]);

  const fetchHouseholds = async (searchQuery?: string) => {
    try {
      const token = await getIdToken();
      const params = new URLSearchParams();
      if (tierFilter) params.set('tier', tierFilter);
      if (statusFilter) params.set('status', statusFilter);
      if (searchQuery || search) params.set('search', searchQuery || search);

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api'}/admin/households?${params}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        setData(await response.json());
      }
    } catch (e) {
      console.error('Failed to load households:', e);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="animate-pulse h-96 bg-gray-200 rounded-xl" />;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Households</h1>
        <p className="text-gray-500">{data?.pagination.total || 0} total households</p>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl p-4 shadow-sm flex flex-wrap gap-4">
        <form onSubmit={(e) => { e.preventDefault(); fetchHouseholds(search); }} className="flex-1 min-w-[200px]">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by name or address..."
              className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-500"
            />
          </div>
        </form>

        <select
          value={tierFilter}
          onChange={(e) => setTierFilter(e.target.value)}
          className="px-4 py-2 border border-gray-200 rounded-lg"
        >
          <option value="">All Tiers</option>
          <option value="ESSENTIALS">Essentials</option>
          <option value="LITE">Lite</option>
          <option value="HAVEN">Haven</option>
          <option value="HAVEN+">Haven+</option>
          <option value="ESTATE">Estate</option>
        </select>

        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-4 py-2 border border-gray-200 rounded-lg"
        >
          <option value="">All Status</option>
          <option value="ACTIVE">Active</option>
          <option value="PENDING">Pending</option>
          <option value="INACTIVE">Inactive</option>
        </select>
      </div>

      {/* Households Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {data?.households.map((h) => (
          <Link
            key={h.id}
            href={`/admin/households/${h.id}`}
            className="bg-white rounded-xl p-5 shadow-sm hover:shadow-md transition"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-haven-100 rounded-lg flex items-center justify-center">
                  <Home className="w-5 h-5 text-haven-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900">{h.name}</h3>
                  <p className="text-sm text-gray-500">{h.address || 'No address'}</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-gray-300" />
            </div>

            <div className="flex flex-wrap gap-2 mb-4">
              <span className={`px-2 py-0.5 rounded text-xs font-medium ${tierColors[h.tier] || 'bg-gray-100'}`}>
                {h.tier}
              </span>
              <span className={`px-2 py-0.5 rounded text-xs font-medium ${statusColors[h.status] || 'bg-gray-100'}`}>
                {h.status}
              </span>
            </div>

            <div className="grid grid-cols-3 gap-3 text-center text-sm">
              <div>
                <p className="font-semibold text-gray-900">{h.memberCount}</p>
                <p className="text-gray-500 text-xs">Members</p>
              </div>
              <div>
                <p className="font-semibold text-gray-900">{h.billCount}</p>
                <p className="text-gray-500 text-xs">Bills</p>
              </div>
              <div>
                <p className="font-semibold text-gray-900">${h.monthlyFunding.toLocaleString()}</p>
                <p className="text-gray-500 text-xs">Monthly</p>
              </div>
            </div>

            <div className="mt-4 pt-4 border-t border-gray-100 flex items-center justify-between text-sm">
              <span className="text-gray-500">Manager: {h.homeManager}</span>
              <span className="text-gray-400">{h.primaryContact?.name}</span>
            </div>
          </Link>
        ))}
      </div>

      {data?.households.length === 0 && (
        <div className="text-center py-12 text-gray-500">No households found</div>
      )}
    </div>
  );
}
