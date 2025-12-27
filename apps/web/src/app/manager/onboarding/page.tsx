'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Users,
  Calendar,
  Clock,
  CheckCircle,
  AlertCircle,
  Play,
  Phone,
  Home,
  ArrowRight,
  Search,
  Loader2,
  Building2,
} from 'lucide-react';
import { getIdToken } from '@/lib/firebase';

interface HouseholdNeedingIntake {
  id: string;
  name: string;
  createdAt: string;
  homeProfile?: {
    addressLine1: string;
    city: string;
    state: string;
  };
  owner: {
    id: string;
    firstName?: string;
    lastName?: string;
    email: string;
    phone?: string;
  };
  householdIntake?: {
    status: string;
    progress: number;
  };
}

export default function ManagerOnboardingDashboard() {
  const router = useRouter();
  const [households, setHouseholds] = useState<HouseholdNeedingIntake[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');

  useEffect(() => {
    fetchHouseholds();
  }, []);

  const fetchHouseholds = async () => {
    setIsLoading(true);
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/intake/pending`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setHouseholds(data);
      }
    } catch (error) {
      console.error('Error fetching households:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredHouseholds = households.filter((h) => {
    const matchesSearch =
      searchQuery === '' ||
      h.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      h.owner.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      h.homeProfile?.addressLine1?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesStatus =
      filterStatus === 'all' ||
      (filterStatus === 'new' && !h.householdIntake) ||
      h.householdIntake?.status === filterStatus;

    return matchesSearch && matchesStatus;
  });

  const groupedHouseholds = {
    needsIntake: filteredHouseholds.filter(
      (h) => !h.householdIntake || h.householdIntake.status === 'PENDING'
    ),
    scheduled: filteredHouseholds.filter((h) => h.householdIntake?.status === 'SCHEDULED'),
    inProgress: filteredHouseholds.filter(
      (h) => h.householdIntake?.status === 'IN_PROGRESS' || h.householdIntake?.status === 'PAUSED'
    ),
  };

  const startIntake = (householdId: string) => {
    router.push(`/manager/onboarding/${householdId}`);
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-haven-champagne-600 mx-auto mb-4" />
          <p className="text-gray-500">Loading households...</p>
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
              <h1 className="text-xl font-bold text-haven-navy-900">
                Household Onboarding
              </h1>
              <p className="text-sm text-gray-500">
                {households.length} households need attention
              </p>
            </div>
            <div className="flex items-center gap-4">
              {/* Search */}
              <div className="relative">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search households..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-9 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none w-64"
                />
              </div>

              {/* Filter */}
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
              >
                <option value="all">All Status</option>
                <option value="new">New (No Intake)</option>
                <option value="PENDING">Pending</option>
                <option value="SCHEDULED">Scheduled</option>
                <option value="IN_PROGRESS">In Progress</option>
                <option value="PAUSED">Paused</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 py-6">
        {/* Stats Cards */}
        <div className="grid grid-cols-4 gap-4 mb-8">
          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <Users className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-haven-navy-900">
                  {groupedHouseholds.needsIntake.length}
                </p>
                <p className="text-sm text-gray-500">New Households</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                <Calendar className="w-5 h-5 text-purple-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-haven-navy-900">
                  {groupedHouseholds.scheduled.length}
                </p>
                <p className="text-sm text-gray-500">Scheduled</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
                <Play className="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-haven-navy-900">
                  {groupedHouseholds.inProgress.length}
                </p>
                <p className="text-sm text-gray-500">In Progress</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-emerald-100 rounded-lg flex items-center justify-center">
                <CheckCircle className="w-5 h-5 text-emerald-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-haven-navy-900">
                  {households.filter((h) => h.householdIntake?.status === 'COMPLETED').length}
                </p>
                <p className="text-sm text-gray-500">Completed</p>
              </div>
            </div>
          </div>
        </div>

        {/* Needs Intake */}
        {groupedHouseholds.needsIntake.length > 0 && (
          <div className="mb-8">
            <div className="flex items-center gap-2 mb-4">
              <AlertCircle className="w-5 h-5 text-amber-500" />
              <h2 className="text-lg font-semibold text-haven-navy-900">
                Needs Intro Call ({groupedHouseholds.needsIntake.length})
              </h2>
            </div>

            <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
              <div className="divide-y divide-gray-100">
                {groupedHouseholds.needsIntake.map((household) => (
                  <div
                    key={household.id}
                    className="p-4 hover:bg-gray-50 transition flex items-center justify-between"
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 bg-haven-champagne-100 rounded-xl flex items-center justify-center">
                        <Home className="w-6 h-6 text-haven-champagne-600" />
                      </div>
                      <div>
                        <h3 className="font-medium text-haven-navy-900">{household.name}</h3>
                        <div className="flex items-center gap-2 text-sm text-gray-500">
                          <Building2 className="w-3 h-3" />
                          {household.homeProfile ? (
                            <span>
                              {household.homeProfile.addressLine1}, {household.homeProfile.city},{' '}
                              {household.homeProfile.state}
                            </span>
                          ) : (
                            <span className="italic">No address yet</span>
                          )}
                        </div>
                        <div className="flex items-center gap-3 mt-1 text-sm">
                          <span className="text-gray-500">
                            {household.owner.firstName} {household.owner.lastName}
                          </span>
                          {household.owner.phone && (
                            <a
                              href={`tel:${household.owner.phone}`}
                              className="text-haven-champagne-600 hover:text-haven-champagne-700 flex items-center gap-1"
                            >
                              <Phone className="w-3 h-3" />
                              {household.owner.phone}
                            </a>
                          )}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs font-medium rounded-full">
                        New
                      </span>
                      <button
                        onClick={() => startIntake(household.id)}
                        className="flex items-center gap-2 px-4 py-2 bg-haven-navy-900 text-white text-sm font-medium rounded-lg hover:bg-haven-navy-800 transition"
                      >
                        Start Intake
                        <ArrowRight className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Scheduled */}
        {groupedHouseholds.scheduled.length > 0 && (
          <div className="mb-8">
            <div className="flex items-center gap-2 mb-4">
              <Calendar className="w-5 h-5 text-purple-500" />
              <h2 className="text-lg font-semibold text-haven-navy-900">
                Scheduled Calls ({groupedHouseholds.scheduled.length})
              </h2>
            </div>

            <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
              <div className="divide-y divide-gray-100">
                {groupedHouseholds.scheduled.map((household) => (
                  <div
                    key={household.id}
                    className="p-4 hover:bg-gray-50 transition flex items-center justify-between"
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center">
                        <Calendar className="w-6 h-6 text-purple-600" />
                      </div>
                      <div>
                        <h3 className="font-medium text-haven-navy-900">{household.name}</h3>
                        <p className="text-sm text-gray-500">
                          {household.owner.firstName} {household.owner.lastName}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <span className="px-2 py-1 bg-purple-100 text-purple-700 text-xs font-medium rounded-full">
                        Scheduled
                      </span>
                      <button
                        onClick={() => startIntake(household.id)}
                        className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white text-sm font-medium rounded-lg hover:bg-purple-700 transition"
                      >
                        <Phone className="w-4 h-4" />
                        Start Call
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* In Progress */}
        {groupedHouseholds.inProgress.length > 0 && (
          <div className="mb-8">
            <div className="flex items-center gap-2 mb-4">
              <Play className="w-5 h-5 text-amber-500" />
              <h2 className="text-lg font-semibold text-haven-navy-900">
                In Progress ({groupedHouseholds.inProgress.length})
              </h2>
            </div>

            <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
              <div className="divide-y divide-gray-100">
                {groupedHouseholds.inProgress.map((household) => (
                  <div
                    key={household.id}
                    className="p-4 hover:bg-gray-50 transition flex items-center justify-between"
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 bg-amber-100 rounded-xl flex items-center justify-center">
                        <Clock className="w-6 h-6 text-amber-600" />
                      </div>
                      <div>
                        <h3 className="font-medium text-haven-navy-900">{household.name}</h3>
                        <p className="text-sm text-gray-500">
                          {household.owner.firstName} {household.owner.lastName}
                        </p>
                        <div className="mt-2 w-32 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                          <div
                            className="h-full bg-amber-500 transition-all duration-300"
                            style={{ width: `${household.householdIntake?.progress || 0}%` }}
                          />
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <span className="text-sm text-gray-500">
                        {household.householdIntake?.progress || 0}% complete
                      </span>
                      <button
                        onClick={() => router.push(`/manager/households/${household.id}/profile`)}
                        className="flex items-center gap-2 px-4 py-2 border border-gray-200 text-gray-700 text-sm font-medium rounded-lg hover:bg-gray-50 transition"
                      >
                        <Building2 className="w-4 h-4" />
                        Build Profile
                      </button>
                      <button
                        onClick={() => startIntake(household.id)}
                        className="flex items-center gap-2 px-4 py-2 bg-amber-500 text-white text-sm font-medium rounded-lg hover:bg-amber-600 transition"
                      >
                        Continue
                        <ArrowRight className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Empty State */}
        {filteredHouseholds.length === 0 && (
          <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
            <Users className="w-12 h-12 text-gray-300 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-600 mb-2">
              {searchQuery ? 'No matching households' : 'No households need onboarding'}
            </h3>
            <p className="text-sm text-gray-400">
              {searchQuery
                ? 'Try adjusting your search criteria'
                : 'All households have completed their intake process'}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
