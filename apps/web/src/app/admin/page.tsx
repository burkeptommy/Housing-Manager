'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import {
  Users,
  Home,
  ClipboardList,
  UserCog,
  Clock,
  CheckCircle,
  AlertCircle,
} from 'lucide-react';

interface DashboardStats {
  overview: {
    totalUsers: number;
    totalHouseholds: number;
    activeHouseholds: number;
    pendingOnboarding: number;
    homeManagers: number;
    handymen: number;
  };
  usersByRole: Array<{ role: string; count: number }>;
  householdsByTier: Array<{ tier: string; count: number }>;
  onboardingByStatus: Array<{ status: string; count: number }>;
  recentActivity: Array<{
    id: string;
    title: string;
    actorName: string;
    householdName: string;
    createdAt: string;
  }>;
}

const tierColors: Record<string, string> = {
  ESSENTIALS: 'bg-gray-100 text-gray-700',
  LITE: 'bg-blue-100 text-blue-700',
  HAVEN: 'bg-haven-100 text-haven-700',
  'HAVEN+': 'bg-purple-100 text-purple-700',
  ESTATE: 'bg-amber-100 text-amber-700',
};

const statusLabels: Record<string, string> = {
  PENDING_CALL: 'Pending Call',
  CALL_SCHEDULED: 'Scheduled',
  CALL_IN_PROGRESS: 'In Progress',
  INTAKE_PARTIAL: 'Partial',
  INTAKE_COMPLETE: 'Complete',
  PROFILE_DELIVERED: 'Delivered',
  ACTIVE: 'Active',
};

export default function AdminDashboardPage() {
  const { getIdToken } = useAuth();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const token = await getIdToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api'}/admin/dashboard`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        setStats(await response.json());
      }
    } catch (e) {
      console.error('Failed to load stats:', e);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="animate-pulse space-y-6">
        <div className="h-8 bg-gray-200 rounded w-48" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-32 bg-gray-200 rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  if (!stats) {
    return <div className="text-center text-gray-500">Failed to load dashboard</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
        <p className="text-gray-500">Haven platform overview</p>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Link href="/admin/users" className="bg-white rounded-xl p-6 shadow-sm hover:shadow-md transition">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
              <Users className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{stats.overview.totalUsers}</p>
              <p className="text-sm text-gray-500">Total Users</p>
            </div>
          </div>
        </Link>

        <Link href="/admin/households" className="bg-white rounded-xl p-6 shadow-sm hover:shadow-md transition">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center">
              <Home className="w-6 h-6 text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {stats.overview.activeHouseholds}
                <span className="text-sm text-gray-400 font-normal">
                  /{stats.overview.totalHouseholds}
                </span>
              </p>
              <p className="text-sm text-gray-500">Active Households</p>
            </div>
          </div>
        </Link>

        <Link href="/admin/onboarding" className="bg-white rounded-xl p-6 shadow-sm hover:shadow-md transition">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center">
              <ClipboardList className="w-6 h-6 text-orange-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{stats.overview.pendingOnboarding}</p>
              <p className="text-sm text-gray-500">Pending Onboarding</p>
            </div>
          </div>
        </Link>

        <Link href="/admin/team" className="bg-white rounded-xl p-6 shadow-sm hover:shadow-md transition">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center">
              <UserCog className="w-6 h-6 text-purple-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {stats.overview.homeManagers + stats.overview.handymen}
              </p>
              <p className="text-sm text-gray-500">Team Members</p>
            </div>
          </div>
        </Link>
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Households by Tier */}
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h2 className="font-semibold text-gray-900 mb-4">Households by Tier</h2>
          <div className="space-y-3">
            {stats.householdsByTier.map((t) => (
              <div key={t.tier} className="flex items-center justify-between">
                <span className={`px-3 py-1 rounded-full text-sm font-medium ${tierColors[t.tier] || 'bg-gray-100'}`}>
                  {t.tier}
                </span>
                <span className="font-semibold text-gray-900">{t.count}</span>
              </div>
            ))}
            {stats.householdsByTier.length === 0 && (
              <p className="text-gray-400 text-sm">No households yet</p>
            )}
          </div>
        </div>

        {/* Onboarding Pipeline */}
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h2 className="font-semibold text-gray-900 mb-4">Onboarding Pipeline</h2>
          <div className="space-y-3">
            {stats.onboardingByStatus.map((s) => (
              <div key={s.status} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  {s.status === 'ACTIVE' ? (
                    <CheckCircle className="w-4 h-4 text-green-500" />
                  ) : s.status === 'PENDING_CALL' ? (
                    <AlertCircle className="w-4 h-4 text-orange-500" />
                  ) : (
                    <Clock className="w-4 h-4 text-blue-500" />
                  )}
                  <span className="text-gray-700">{statusLabels[s.status] || s.status}</span>
                </div>
                <span className="font-semibold text-gray-900">{s.count}</span>
              </div>
            ))}
            {stats.onboardingByStatus.length === 0 && (
              <p className="text-gray-400 text-sm">No onboarding sessions</p>
            )}
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-xl p-6 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-semibold text-gray-900">Recent Activity</h2>
          <Link href="/admin/activity" className="text-sm text-haven-600 hover:underline">
            View all
          </Link>
        </div>
        <div className="divide-y divide-gray-100">
          {stats.recentActivity.map((activity) => (
            <div key={activity.id} className="py-3 flex items-center justify-between">
              <div>
                <p className="font-medium text-gray-900">{activity.title}</p>
                <p className="text-sm text-gray-500">
                  {activity.actorName} {activity.householdName && `• ${activity.householdName}`}
                </p>
              </div>
              <span className="text-xs text-gray-400">
                {new Date(activity.createdAt).toLocaleDateString()}
              </span>
            </div>
          ))}
          {stats.recentActivity.length === 0 && (
            <p className="py-4 text-gray-400 text-sm text-center">No recent activity</p>
          )}
        </div>
      </div>
    </div>
  );
}
