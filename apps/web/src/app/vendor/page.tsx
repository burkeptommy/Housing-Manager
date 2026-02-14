'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import type { VendorJobBoardItem, VendorWorkOrderStatus } from '@haven/core';
import { Card, Badge, Button, Avatar, EmptyState } from '@/components/ui';
import { images } from '@/lib/images';
import {
  ClipboardList,
  DollarSign,
  MapPin,
  Calendar,
  Clock,
  Home,
  ChevronRight,
  Loader2,
  Briefcase,
  TrendingUp,
} from 'lucide-react';

// ============================================================================
// MOCK DATA
// ============================================================================

const mockJobs: VendorJobBoardItem[] = [
  {
    id: 'wo-001',
    title: 'Fix Shingles on South-Facing Roof',
    description:
      'Several shingles have come loose after the recent storm. Need to replace approximately 20 shingles and check for any water damage.',
    status: 'OPEN',
    scheduledStart: '2024-12-20T09:00:00Z',
    scheduledEnd: '2024-12-20T14:00:00Z',
    estimatedCost: 850,
    serviceArea: 'Malibu',
    household: {
      id: 'h-malibu',
      name: 'Malibu Mansion',
    },
    createdAt: '2024-12-17T10:00:00Z',
  },
  {
    id: 'wo-002',
    title: 'Gutter Cleaning and Repair',
    description: 'Annual gutter cleaning plus repair of a section that has come loose from the fascia.',
    status: 'OPEN',
    scheduledStart: '2024-12-21T10:00:00Z',
    scheduledEnd: '2024-12-21T13:00:00Z',
    estimatedCost: 350,
    serviceArea: 'Malibu',
    household: {
      id: 'h-malibu',
      name: 'Malibu Mansion',
    },
    createdAt: '2024-12-16T14:00:00Z',
  },
  {
    id: 'wo-003',
    title: 'Replace Bathroom Exhaust Fan',
    description: 'Master bathroom exhaust fan is making noise and not venting properly. Need replacement.',
    status: 'OPEN',
    scheduledStart: null,
    scheduledEnd: null,
    estimatedCost: 275,
    serviceArea: 'Beverly Hills',
    household: {
      id: 'h-beverly',
      name: 'Beverly Hills Estate',
    },
    createdAt: '2024-12-15T09:00:00Z',
  },
];

const STATUS_STYLES: Record<VendorWorkOrderStatus, { variant: 'success' | 'warning' | 'info' | 'error' | 'neutral'; label: string }> = {
  DRAFT: { variant: 'neutral', label: 'Draft' },
  REQUESTED: { variant: 'info', label: 'Requested' },
  SCHEDULED: { variant: 'info', label: 'Scheduled' },
  OPEN: { variant: 'success', label: 'Open' },
  ASSIGNED: { variant: 'warning', label: 'Assigned' },
  IN_PROGRESS: { variant: 'warning', label: 'In Progress' },
  COMPLETED: { variant: 'success', label: 'Completed' },
  VERIFIED: { variant: 'success', label: 'Verified' },
  CANCELLED: { variant: 'error', label: 'Cancelled' },
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function formatDate(dateStr: string | null): string {
  if (!dateStr) return 'Flexible';
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  });
}

function formatTimeWindow(start: string | null, end: string | null): string {
  if (!start) return 'TBD';
  const startDate = new Date(start);
  const startTime = startDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  if (end) {
    const endDate = new Date(end);
    const endTime = endDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
    return `${startTime} - ${endTime}`;
  }
  return startTime;
}

function formatCurrency(amount: number | null): string {
  if (amount === null) return 'Quote Required';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(amount);
}

function formatCurrentDate(): string {
  return new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric'
  });
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Hero Header for Vendor
function HeroHeader({ stats }: { stats: { openJobs: number; totalValue: number; serviceAreas: number } }) {
  return (
    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-orange-600 via-orange-500 to-amber-500 p-8 text-white mb-8">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 right-0 w-96 h-96 bg-white rounded-full -translate-y-1/2 translate-x-1/2" />
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-white rounded-full translate-y-1/2 -translate-x-1/2" />
      </div>

      <div className="relative">
        <div className="flex items-start justify-between mb-8">
          <div>
            <p className="text-orange-200 text-sm font-medium mb-1">{formatCurrentDate()}</p>
            <h1 className="text-3xl lg:text-4xl font-bold tracking-tight text-white">
              Job Board
            </h1>
            <p className="text-orange-200 mt-2">Available jobs in your service area</p>
          </div>
          <Avatar name="Ace Roofing" size="xl" />
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <Briefcase className="w-4 h-4 text-orange-200" />
              <p className="text-orange-200 text-xs font-medium uppercase tracking-wider">Open Jobs</p>
            </div>
            <p className="text-3xl font-bold">{stats.openJobs}</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <DollarSign className="w-4 h-4 text-emerald-300" />
              <p className="text-orange-200 text-xs font-medium uppercase tracking-wider">Total Value</p>
            </div>
            <p className="text-3xl font-bold">{formatCurrency(stats.totalValue)}</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <MapPin className="w-4 h-4 text-purple-300" />
              <p className="text-orange-200 text-xs font-medium uppercase tracking-wider">Service Areas</p>
            </div>
            <p className="text-3xl font-bold">{stats.serviceAreas}</p>
          </div>
        </div>
      </div>
    </div>
  );
}

// Area Filter
function AreaFilter({ areas, selected, onSelect }: { areas: string[]; selected: string; onSelect: (area: string) => void }) {
  return (
    <div className="flex gap-2 flex-wrap mb-6">
      <button
        onClick={() => onSelect('all')}
        className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
          selected === 'all'
            ? 'bg-orange-600 text-white shadow-lg shadow-orange-500/20'
            : 'bg-neutral-100 text-neutral-600 hover:bg-neutral-200'
        }`}
      >
        All Areas
      </button>
      {areas.map((area) => (
        <button
          key={area}
          onClick={() => onSelect(area)}
          className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            selected === area
              ? 'bg-orange-600 text-white shadow-lg shadow-orange-500/20'
              : 'bg-neutral-100 text-neutral-600 hover:bg-neutral-200'
          }`}
        >
          {area}
        </button>
      ))}
    </div>
  );
}

// Job Card
function JobCard({ job, onClaim, isClaiming }: { job: VendorJobBoardItem; onClaim: () => void; isClaiming: boolean }) {
  const status = STATUS_STYLES[job.status] || STATUS_STYLES.OPEN;

  return (
    <Card hover className="overflow-hidden">
      <div className="flex flex-col lg:flex-row lg:items-start gap-4">
        {/* Job Info */}
        <div className="flex-1">
          <div className="flex items-start justify-between gap-4 mb-3">
            <div>
              <Link
                href={`/vendor/jobs/${job.id}`}
                className="text-lg font-bold text-neutral-900 hover:text-orange-600 transition-colors"
              >
                {job.title}
              </Link>
              <div className="flex items-center gap-2 mt-2">
                <Badge variant={status.variant} size="sm">{status.label}</Badge>
                {job.serviceArea && (
                  <Badge variant="neutral" size="sm" icon={<MapPin className="w-3 h-3" />}>
                    {job.serviceArea}
                  </Badge>
                )}
              </div>
            </div>
            <div className="text-right">
              <p className="text-xl font-bold text-neutral-900">
                {formatCurrency(job.estimatedCost)}
              </p>
              <p className="text-xs text-neutral-500">Estimated</p>
            </div>
          </div>

          <p className="text-neutral-600 text-sm mb-4 line-clamp-2">
            {job.description}
          </p>

          <div className="flex items-center gap-4 text-sm text-neutral-500">
            <span className="flex items-center gap-1.5">
              <Home className="w-4 h-4" />
              {job.household.name}
            </span>
            <span className="flex items-center gap-1.5">
              <Calendar className="w-4 h-4" />
              {formatDate(job.scheduledStart)}
            </span>
            <span className="flex items-center gap-1.5">
              <Clock className="w-4 h-4" />
              {formatTimeWindow(job.scheduledStart, job.scheduledEnd)}
            </span>
          </div>
        </div>

        {/* Actions */}
        <div className="flex lg:flex-col gap-2">
          <Link href={`/vendor/jobs/${job.id}`} className="flex-1 lg:flex-none">
            <Button variant="secondary" className="w-full">
              View Details
            </Button>
          </Link>
          <Button
            onClick={onClaim}
            isLoading={isClaiming}
            className="flex-1 lg:flex-none"
          >
            Claim Job
          </Button>
        </div>
      </div>
    </Card>
  );
}

// Empty Jobs State
function EmptyJobs() {
  return (
    <Card className="text-center py-12">
      <div className="w-16 h-16 rounded-2xl bg-neutral-100 flex items-center justify-center mx-auto mb-4">
        <ClipboardList className="w-8 h-8 text-neutral-400" />
      </div>
      <h3 className="text-lg font-bold text-neutral-900 mb-2">No open jobs</h3>
      <p className="text-neutral-600">
        Check back later for new job opportunities in your area.
      </p>
    </Card>
  );
}

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function JobBoardPage() {
  const [jobs, setJobs] = useState<VendorJobBoardItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedArea, setSelectedArea] = useState<string>('all');
  const [claimingId, setClaimingId] = useState<string | null>(null);

  const loadJobs = useCallback(async () => {
    setIsLoading(true);
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 500));
    setJobs(mockJobs);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    loadJobs();
  }, [loadJobs]);

  const handleClaimJob = async (jobId: string) => {
    setClaimingId(jobId);
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000));
    // Remove claimed job from list
    setJobs((prev) => prev.filter((j) => j.id !== jobId));
    setClaimingId(null);
    // In production, would redirect to /vendor/schedule
  };

  // Get unique service areas for filter
  const serviceAreas = [...new Set(jobs.map((j) => j.serviceArea).filter(Boolean))] as string[];

  const filteredJobs = selectedArea === 'all' ? jobs : jobs.filter((j) => j.serviceArea === selectedArea);

  const stats = {
    openJobs: filteredJobs.length,
    totalValue: filteredJobs.reduce((sum, j) => sum + (j.estimatedCost || 0), 0),
    serviceAreas: serviceAreas.length,
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="w-8 h-8 animate-spin text-orange-600" />
          <p className="text-neutral-500">Loading job board...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-20">
      {/* Hero Header */}
      <HeroHeader stats={stats} />

      {/* Area Filter */}
      {serviceAreas.length > 0 && (
        <AreaFilter
          areas={serviceAreas}
          selected={selectedArea}
          onSelect={setSelectedArea}
        />
      )}

      {/* Job List */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-bold text-neutral-900">Available Jobs</h2>
          <span className="text-sm text-neutral-500">{filteredJobs.length} jobs</span>
        </div>

        {filteredJobs.length === 0 ? (
          <EmptyJobs />
        ) : (
          <div className="space-y-4">
            {filteredJobs.map((job) => (
              <JobCard
                key={job.id}
                job={job}
                onClaim={() => handleClaimJob(job.id)}
                isClaiming={claimingId === job.id}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
