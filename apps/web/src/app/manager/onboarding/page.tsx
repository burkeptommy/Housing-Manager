'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  Users,
  Calendar,
  Clock,
  CheckCircle,
  AlertCircle,
  Play,
  Phone,
  Home,
  ChevronRight,
  Search,
  Loader2,
  User,
} from 'lucide-react';
import { getIdToken } from '@/lib/firebase';

interface QueueItem {
  id: string;
  householdId: string;
  status: string;
  homeownerName: string;
  homeownerEmail: string;
  homeownerPhone: string;
  propertyAddress: string;
  biggestChallenge: string;
  selectedTier: string;
  callScheduledFor: string | null;
  assignedManager: string | null;
  progress: number;
  enrichmentHighlights: string[];
  createdAt: string;
}

const statusConfig: Record<string, { label: string; color: string; icon: React.ComponentType<{ className?: string }> }> = {
  PENDING_CALL: { label: 'Needs Call', color: 'orange', icon: Phone },
  SIGNUP_COMPLETE: { label: 'Needs Call', color: 'orange', icon: Phone },
  CALL_SCHEDULED: { label: 'Scheduled', color: 'blue', icon: Calendar },
  CALL_IN_PROGRESS: { label: 'On Call', color: 'green', icon: Phone },
  INTAKE_PARTIAL: { label: 'Follow-up Needed', color: 'yellow', icon: AlertCircle },
  INTAKE_COMPLETE: { label: 'Complete', color: 'green', icon: CheckCircle },
  PROFILE_BUILDING: { label: 'Building Profile', color: 'purple', icon: User },
  PROFILE_DELIVERED: { label: 'Delivered', color: 'green', icon: CheckCircle },
  ACTIVE: { label: 'Active', color: 'green', icon: CheckCircle },
};

const challengeLabels: Record<string, string> = {
  bills: '💳 Bills & Payments',
  maintenance: '🔧 Home Maintenance',
  vendors: '👷 Vendor Coordination',
  family: '👨‍👩‍👧‍👦 Family Logistics',
  everything: '🌟 Everything',
};

export default function OnboardingQueuePage() {
  const router = useRouter();
  const [queue, setQueue] = useState<QueueItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>('active');
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    fetchQueue();
  }, [filter]);

  const fetchQueue = async () => {
    try {
      setLoading(true);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      const statusParam = filter === 'active' ? '' : `?status=${filter}`;

      const response = await fetch(`${apiUrl}/manager/onboarding/queue${statusParam}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        setQueue(await response.json());
      }
    } catch (error) {
      console.error('Failed to load queue:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredQueue = queue.filter((item) => {
    if (!searchQuery) return true;
    const query = searchQuery.toLowerCase();
    return (
      item.homeownerName.toLowerCase().includes(query) ||
      item.homeownerEmail?.toLowerCase().includes(query) ||
      item.propertyAddress.toLowerCase().includes(query)
    );
  });

  const getStatusBadge = (status: string) => {
    const config = statusConfig[status] || { label: status, color: 'gray', icon: Clock };
    const Icon = config.icon;

    const colorClasses: Record<string, string> = {
      orange: 'bg-orange-100 text-orange-700',
      blue: 'bg-blue-100 text-blue-700',
      green: 'bg-green-100 text-green-700',
      yellow: 'bg-yellow-100 text-yellow-700',
      purple: 'bg-purple-100 text-purple-700',
      gray: 'bg-gray-100 text-gray-700',
    };

    return (
      <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${colorClasses[config.color] || colorClasses.gray}`}>
        <Icon className="w-3 h-3" />
        {config.label}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-haven-champagne-600 mx-auto mb-4" />
          <p className="text-gray-500">Loading queue...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-5xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-xl font-bold text-haven-navy-900">
                Onboarding Queue
              </h1>
              <p className="text-sm text-gray-500">
                {queue.length} household{queue.length !== 1 ? 's' : ''} waiting
              </p>
            </div>

            <div className="flex items-center gap-4">
              {/* Search */}
              <div className="relative">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-9 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none w-48"
                />
              </div>

              {/* Filter */}
              <div className="flex gap-2">
                {[
                  { key: 'active', label: 'Active' },
                  { key: 'PENDING_CALL', label: 'Needs Call' },
                  { key: 'INTAKE_PARTIAL', label: 'Follow-up' },
                  { key: 'INTAKE_COMPLETE', label: 'Complete' },
                ].map((f) => (
                  <button
                    key={f.key}
                    onClick={() => setFilter(f.key)}
                    className={`px-3 py-1.5 rounded-lg text-sm transition ${
                      filter === f.key
                        ? 'bg-haven-navy-900 text-white'
                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                    }`}
                  >
                    {f.label}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-4 py-6">
        {/* Queue List */}
        <div className="space-y-4">
          {filteredQueue.length === 0 ? (
            <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
              <Users className="w-12 h-12 text-gray-300 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-600 mb-2">
                No households in queue
              </h3>
              <p className="text-sm text-gray-400">
                {filter !== 'active' ? 'Try a different filter' : 'All households have been processed'}
              </p>
            </div>
          ) : (
            filteredQueue.map((item) => (
              <Link
                key={item.id}
                href={`/manager/onboarding/${item.id}`}
                className="block bg-white rounded-xl border border-gray-100 p-5 hover:shadow-md transition"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    {/* Header Row */}
                    <div className="flex items-center gap-3 mb-2">
                      <div className="w-10 h-10 bg-haven-champagne-100 rounded-full flex items-center justify-center">
                        <User className="w-5 h-5 text-haven-champagne-600" />
                      </div>
                      <div>
                        <div className="font-semibold text-haven-navy-900">
                          {item.homeownerName}
                        </div>
                        <div className="text-sm text-gray-500">
                          {item.homeownerEmail}
                          {item.homeownerPhone && ` • ${item.homeownerPhone}`}
                        </div>
                      </div>
                      {getStatusBadge(item.status)}
                    </div>

                    {/* Property */}
                    <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
                      <Home className="w-4 h-4" />
                      {item.propertyAddress}
                    </div>

                    {/* Details Row */}
                    <div className="flex items-center gap-4 text-sm">
                      {item.biggestChallenge && (
                        <span className="text-gray-500">
                          {challengeLabels[item.biggestChallenge] || item.biggestChallenge}
                        </span>
                      )}
                      {item.selectedTier && (
                        <span className="px-2 py-0.5 bg-haven-champagne-100 text-haven-champagne-700 rounded">
                          {item.selectedTier}
                        </span>
                      )}
                      {item.enrichmentHighlights && item.enrichmentHighlights.length > 0 && (
                        <span className="text-gray-400">
                          {item.enrichmentHighlights.join(' • ')}
                        </span>
                      )}
                    </div>

                    {/* Progress Bar */}
                    {item.progress > 0 && (
                      <div className="mt-3">
                        <div className="flex justify-between text-xs text-gray-500 mb-1">
                          <span>Intake Progress</span>
                          <span>{item.progress}%</span>
                        </div>
                        <div className="w-full bg-gray-100 rounded-full h-1.5">
                          <div
                            className="bg-haven-champagne-500 h-1.5 rounded-full transition-all"
                            style={{ width: `${item.progress}%` }}
                          />
                        </div>
                      </div>
                    )}
                  </div>

                  <ChevronRight className="w-5 h-5 text-gray-300" />
                </div>
              </Link>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
