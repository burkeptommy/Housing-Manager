'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { getIdToken } from '@/lib/firebase';
import {
  Home,
  Search,
  ChevronRight,
  Users,
  FileText,
  Wrench,
  Loader2,
} from 'lucide-react';

interface Household {
  id: string;
  name: string;
  tier: string;
  status: string;
  address: {
    full: string;
  } | null;
  homeowners: Array<{ name: string; email: string; phone: string }>;
  memberCount: number;
  billCount: number;
  vendorCount: number;
  monthlyFunding: number;
  totalMonthlyBills: number;
}

export default function ManagerHouseholdsPage() {
  const [households, setHouseholds] = useState<Household[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchHouseholds();
  }, []);

  const fetchHouseholds = async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/manager/households`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        setHouseholds(await response.json());
      }
    } catch (error) {
      console.error('Failed to load households:', error);
    } finally {
      setLoading(false);
    }
  };

  const filtered = households.filter((h) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      h.name.toLowerCase().includes(q) ||
      h.address?.full.toLowerCase().includes(q) ||
      h.homeowners.some((o) => o.name.toLowerCase().includes(q))
    );
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">My Households</h1>
          <p className="text-gray-500">{households.length} households assigned</p>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search households..."
          className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
        />
      </div>

      {/* Households Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map((h) => (
          <Link
            key={h.id}
            href={`/manager/households/${h.id}`}
            className="bg-white rounded-xl p-5 shadow-sm hover:shadow-md transition border border-gray-100"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
                  <Home className="w-5 h-5 text-indigo-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900">{h.name}</h3>
                  <p className="text-sm text-gray-500">{h.address?.full || 'No address'}</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-gray-300" />
            </div>

            <div className="flex flex-wrap gap-2 mb-4">
              <span className="px-2 py-0.5 bg-indigo-100 text-indigo-700 rounded text-xs font-medium">
                {h.tier}
              </span>
              <span className="px-2 py-0.5 bg-green-100 text-green-700 rounded text-xs font-medium">
                {h.status}
              </span>
            </div>

            <div className="grid grid-cols-3 gap-2 text-center text-sm mb-4">
              <div className="flex items-center justify-center gap-1 text-gray-600">
                <Users className="w-3 h-3" />
                <span>{h.memberCount}</span>
              </div>
              <div className="flex items-center justify-center gap-1 text-gray-600">
                <FileText className="w-3 h-3" />
                <span>{h.billCount}</span>
              </div>
              <div className="flex items-center justify-center gap-1 text-gray-600">
                <Wrench className="w-3 h-3" />
                <span>{h.vendorCount}</span>
              </div>
            </div>

            <div className="pt-3 border-t border-gray-100 flex justify-between text-sm">
              <span className="text-gray-500">Monthly</span>
              <span className="font-semibold text-gray-900">
                ${(h.totalMonthlyBills || 0).toLocaleString()}
              </span>
            </div>
          </Link>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="text-center py-12 text-gray-500">
          {search ? 'No households match your search' : 'No households assigned yet'}
        </div>
      )}
    </div>
  );
}
