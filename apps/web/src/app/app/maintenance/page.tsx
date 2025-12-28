'use client';

import { useState, useMemo, useEffect, useCallback } from 'react';
import Image from 'next/image';
import {
  Thermometer,
  Droplets,
  Zap,
  Flame,
  Home,
  AlertTriangle,
  AlertCircle,
  CheckCircle2,
  Clock,
  Star,
  FileText,
  Search,
  Wrench,
  Settings,
  X,
  Activity,
  Waves,
  Refrigerator,
  WashingMachine,
  AirVent,
  BadgeCheck,
  Loader2,
  Calendar,
  Headphones,
  Check,
  Camera,
  Shield,
  ClipboardCheck,
  UserCheck,
  Car,
  TreeDeciduous,
  ShieldAlert,
} from 'lucide-react';
import { getApiClient } from '@/lib/api';
import { useAuth } from '@/contexts/auth-context';
import { getDemoImage } from '@/lib/imageUtils';

// ============================================================================
// TYPES
// ============================================================================

type AssetHealth = 'excellent' | 'good' | 'fair' | 'needs_attention' | 'critical';
type AlertSeverity = 'critical' | 'warning' | 'info' | 'success';
type ManagerStatus = 'scheduling' | 'ordered' | 'scheduled' | 'completed' | 'monitoring';

interface HomeAsset {
  id: string;
  name: string;
  category: string;
  brand: string;
  model?: string;
  icon: typeof Thermometer;
  installDate: Date;
  expectedLifespan: number;
  lastService?: Date;
  lastServiceVendor?: string;
  nextServiceDue?: Date;
  nextServiceMonth?: string;
  health: AssetHealth;
  location?: string;
  warrantyExpires?: Date;
  notes?: string;
  serialNumber?: string;
}

interface MaintenanceAlert {
  id: string;
  assetId?: string;
  assetName: string;
  message: string;
  severity: AlertSeverity;
  daysOverdue?: number;
  dueDate?: Date;
  managerStatus: ManagerStatus;
  managerMessage: string;
}

interface ScheduledService {
  id: string;
  date: Date;
  assetName: string;
  serviceType: string;
  vendorName: string;
  vendorId?: string;
  isConfirmed: boolean;
}

interface WarrantyAlert {
  id: string;
  assetName: string;
  assetId: string;
  expiresAt: Date;
  monthsRemaining: number;
  recommendation: string;
}

interface HandymanVisit {
  id: string;
  date: Date;
  handymanName: string;
  handymanAvatar?: string;
  tasksCompleted: string[];
  notes?: string;
  photos?: string[];
  recommendations?: { item: string; action: string }[];
}

interface TrustedVendor {
  id: string;
  name: string;
  company: string;
  trade: string;
  rating: number;
  jobsCompleted: number;
  initials: string;
  isPreferred?: boolean;
}

interface ServiceRecord {
  id: string;
  assetId: string;
  assetName: string;
  date: Date;
  vendor?: string;
  vendorId?: string;
  serviceType: string;
  description: string;
  cost?: number;
  invoiceUrl?: string;
  scheduledBy: 'Sarah' | 'Homeowner' | 'Auto';
  diy: boolean;
}

// ============================================================================
// CONSTANTS
// ============================================================================

const HOUSING_MANAGER = {
  name: 'Sarah',
  title: 'Your Home Manager',
  avatar: getDemoImage('avatar-female', 100, 100, 'sarah-manager'),
};

const healthConfig: Record<AssetHealth, { color: string; bgColor: string; label: string }> = {
  excellent: { color: 'text-emerald-700', bgColor: 'bg-emerald-100', label: 'Excellent' },
  good: { color: 'text-green-700', bgColor: 'bg-green-100', label: 'Good' },
  fair: { color: 'text-yellow-700', bgColor: 'bg-yellow-100', label: 'Fair' },
  needs_attention: { color: 'text-orange-700', bgColor: 'bg-orange-100', label: 'Needs Attention' },
  critical: { color: 'text-red-700', bgColor: 'bg-red-100', label: 'Critical' },
};

const alertConfig: Record<AlertSeverity, { color: string; bgColor: string; borderColor: string; icon: typeof AlertTriangle }> = {
  critical: { color: 'text-red-700', bgColor: 'bg-red-50', borderColor: 'border-red-200', icon: AlertTriangle },
  warning: { color: 'text-amber-700', bgColor: 'bg-amber-50', borderColor: 'border-amber-200', icon: AlertCircle },
  info: { color: 'text-blue-700', bgColor: 'bg-blue-50', borderColor: 'border-blue-200', icon: Clock },
  success: { color: 'text-emerald-700', bgColor: 'bg-emerald-50', borderColor: 'border-emerald-200', icon: CheckCircle2 },
};

// ============================================================================
// MOCK DATA
// ============================================================================

const MOCK_ASSETS: HomeAsset[] = [
  {
    id: 'hvac-main',
    name: 'Main HVAC System',
    category: 'Climate',
    brand: 'Carrier',
    model: 'Infinity 26',
    icon: AirVent,
    installDate: new Date(2019, 5, 15),
    expectedLifespan: 15,
    lastService: new Date(2024, 3, 10),
    lastServiceVendor: 'AirFlow HVAC',
    nextServiceDue: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'January',
    health: 'needs_attention',
    location: 'Attic',
    warrantyExpires: new Date(2029, 5, 15),
    serialNumber: 'CAR-INF26-2019-0615',
  },
  {
    id: 'water-heater',
    name: 'Water Heater',
    category: 'Plumbing',
    brand: 'Rheem',
    model: 'Performance Plus',
    icon: Flame,
    installDate: new Date(2020, 8, 22),
    expectedLifespan: 12,
    lastService: new Date(2024, 9, 5),
    lastServiceVendor: 'Elite Plumbing Co.',
    nextServiceDue: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'February',
    health: 'good',
    location: 'Garage',
    warrantyExpires: new Date(2026, 8, 22),
    serialNumber: 'RHM-PP50-2020-0922',
  },
  {
    id: 'roof',
    name: 'Roof System',
    category: 'Structure',
    brand: 'GAF',
    model: 'Timberline HDZ',
    icon: Home,
    installDate: new Date(2018, 3, 10),
    expectedLifespan: 30,
    lastService: new Date(2024, 10, 15),
    lastServiceVendor: 'ABC Roofing',
    nextServiceDue: new Date(Date.now() + 335 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'November',
    health: 'excellent',
    location: 'Exterior',
  },
  {
    id: 'pool-pump',
    name: 'Pool Equipment',
    category: 'Pool',
    brand: 'Pentair',
    model: 'IntelliFlo VSF',
    icon: Waves,
    installDate: new Date(2021, 4, 1),
    expectedLifespan: 10,
    lastService: new Date(2024, 8, 20),
    lastServiceVendor: 'Crystal Clear Pools',
    nextServiceDue: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'January',
    health: 'good',
    location: 'Backyard',
    warrantyExpires: new Date(2025, 3, 1), // Expires in ~4 months
    serialNumber: 'PEN-VSF-2021-0501',
  },
  {
    id: 'electrical-panel',
    name: 'Electrical Panel',
    category: 'Electrical',
    brand: 'Square D',
    model: 'QO 200A',
    icon: Zap,
    installDate: new Date(2015, 2, 8),
    expectedLifespan: 40,
    lastService: new Date(2023, 11, 12),
    lastServiceVendor: 'Wilson Electric',
    nextServiceDue: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'June',
    health: 'excellent',
    location: 'Garage',
  },
  {
    id: 'water-softener',
    name: 'Water Softener',
    category: 'Plumbing',
    brand: 'Culligan',
    model: 'HE Series',
    icon: Droplets,
    installDate: new Date(2022, 1, 14),
    expectedLifespan: 15,
    lastService: new Date(2024, 7, 30),
    lastServiceVendor: 'DIY',
    nextServiceDue: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    health: 'good',
    location: 'Garage',
    notes: 'Salt refill needed every 2 months',
  },
  {
    id: 'refrigerator',
    name: 'Kitchen Refrigerator',
    category: 'Appliances',
    brand: 'Sub-Zero',
    model: 'BI-36U',
    icon: Refrigerator,
    installDate: new Date(2020, 6, 1),
    expectedLifespan: 20,
    lastService: new Date(2024, 5, 15),
    lastServiceVendor: 'Sub-Zero Authorized Service',
    nextServiceDue: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'June',
    health: 'excellent',
    location: 'Kitchen',
    warrantyExpires: new Date(2025, 6, 1),
    serialNumber: 'SZ-BI36U-2020-0701',
  },
  {
    id: 'washer-dryer',
    name: 'Washer & Dryer',
    category: 'Appliances',
    brand: 'LG',
    model: 'WM4500HBA / DLEX4500B',
    icon: WashingMachine,
    installDate: new Date(2023, 0, 20),
    expectedLifespan: 12,
    lastService: new Date(2024, 6, 10),
    lastServiceVendor: 'Appliance Pros',
    nextServiceDue: new Date(Date.now() + 150 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'May',
    health: 'excellent',
    location: 'Laundry Room',
    warrantyExpires: new Date(2026, 0, 20),
    serialNumber: 'LG-WM4500-2023-0120',
  },
  // Vehicles
  {
    id: 'vehicle-bmw',
    name: '2022 BMW X5',
    category: 'Vehicles',
    brand: 'BMW',
    model: 'X5 xDrive40i',
    icon: Car,
    installDate: new Date(2022, 2, 15),
    expectedLifespan: 12,
    lastService: new Date(2024, 10, 5),
    lastServiceVendor: 'BMW of Greenwich',
    nextServiceDue: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'March',
    health: 'excellent',
    location: 'Garage',
    warrantyExpires: new Date(2026, 2, 15),
    serialNumber: '5UXCR4C05N9D12345',
    notes: 'Oil change every 10,000 miles',
  },
  {
    id: 'vehicle-tesla',
    name: '2023 Tesla Model S',
    category: 'Vehicles',
    brand: 'Tesla',
    model: 'Model S Long Range',
    icon: Car,
    installDate: new Date(2023, 6, 1),
    expectedLifespan: 15,
    lastService: new Date(2024, 8, 20),
    lastServiceVendor: 'Tesla Service Center',
    nextServiceDue: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'June',
    health: 'excellent',
    location: 'Garage',
    warrantyExpires: new Date(2027, 6, 1),
    serialNumber: '5YJSA1E29NF123456',
    notes: 'Annual service recommended',
  },
  // Outdoor/Landscaping
  {
    id: 'irrigation-system',
    name: 'Irrigation System',
    category: 'Outdoor',
    brand: 'Rain Bird',
    model: 'ESP-TM2',
    icon: TreeDeciduous,
    installDate: new Date(2020, 3, 10),
    expectedLifespan: 15,
    lastService: new Date(2024, 9, 15),
    lastServiceVendor: 'Green Thumb Landscaping',
    nextServiceDue: new Date(Date.now() + 120 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'April',
    health: 'good',
    location: 'Exterior',
    notes: 'Winterize in November, activate in April',
  },
  // Security
  {
    id: 'security-system',
    name: 'Security System',
    category: 'Security',
    brand: 'ADT',
    model: 'Command Pro',
    icon: ShieldAlert,
    installDate: new Date(2021, 1, 1),
    expectedLifespan: 10,
    lastService: new Date(2024, 11, 1),
    lastServiceVendor: 'ADT Security',
    nextServiceDue: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
    nextServiceMonth: 'December',
    health: 'excellent',
    location: 'Whole Home',
    notes: '24/7 monitoring active',
  },
];

const MOCK_ALERTS: MaintenanceAlert[] = [
  {
    id: 'a1',
    assetId: 'hvac-main',
    assetName: 'Main HVAC System',
    message: 'HVAC Service Overdue',
    severity: 'critical',
    daysOverdue: 14,
    managerStatus: 'scheduling',
    managerMessage: 'Sarah is scheduling with AirFlow HVAC',
  },
  {
    id: 'a2',
    assetId: 'water-softener',
    assetName: 'Water Softener',
    message: 'Water filter expires in 2 weeks',
    severity: 'warning',
    dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    managerStatus: 'ordered',
    managerMessage: 'Replacement ordered, arrives Dec 28',
  },
  {
    id: 'a3',
    assetId: 'roof',
    assetName: 'Roof System',
    message: 'Annual inspection completed',
    severity: 'success',
    managerStatus: 'completed',
    managerMessage: 'No issues found',
  },
];

const MOCK_SCHEDULED_SERVICES: ScheduledService[] = [
  {
    id: 'svc-1',
    date: new Date(2025, 0, 7),
    assetName: 'Main HVAC System',
    serviceType: 'HVAC Service',
    vendorName: 'AirFlow HVAC',
    vendorId: 'v1',
    isConfirmed: true,
  },
  {
    id: 'svc-2',
    date: new Date(2025, 0, 15),
    assetName: 'Gutters',
    serviceType: 'Gutter Cleaning',
    vendorName: 'Clean Gutters Co',
    isConfirmed: true,
  },
  {
    id: 'svc-3',
    date: new Date(2025, 1, 1),
    assetName: 'Pool Equipment',
    serviceType: 'Pool Opening Prep',
    vendorName: 'Crystal Clear Pools',
    vendorId: 'v4',
    isConfirmed: false,
  },
  {
    id: 'svc-4',
    date: new Date(2025, 2, 15),
    assetName: 'Lawn',
    serviceType: 'Spring Lawn Care',
    vendorName: 'Green Thumb Landscaping',
    isConfirmed: false,
  },
];

const MOCK_WARRANTY_ALERTS: WarrantyAlert[] = [
  {
    id: 'war-1',
    assetName: 'Pool Pump',
    assetId: 'pool-pump',
    expiresAt: new Date(2025, 3, 1),
    monthsRemaining: 4,
    recommendation: 'Schedule inspection before warranty ends to catch any issues.',
  },
];

const MOCK_HANDYMAN_VISITS: HandymanVisit[] = [
  {
    id: 'hv-1',
    date: new Date(2024, 11, 15),
    handymanName: 'Mike',
    handymanAvatar: getDemoImage('avatar-male', 100, 100, 'mike-handyman'),
    tasksCompleted: [
      'Changed HVAC filter',
      'Checked smoke detector batteries',
      'Inspected water heater',
      'Tested garage door sensors',
    ],
    notes: 'Noticed deck boards slightly warped. Recommend sealing before spring.',
    photos: [getDemoImage('home-repair', 300, 200, 'deck-inspection')],
    recommendations: [
      { item: 'Deck', action: 'Get quote for deck sealing' },
    ],
  },
];

const MOCK_VENDORS: TrustedVendor[] = [
  { id: 'v1', name: 'AirFlow HVAC', company: 'AirFlow HVAC Services', trade: 'HVAC', rating: 4.9, jobsCompleted: 8, initials: 'AH', isPreferred: true },
  { id: 'v2', name: 'Elite Plumbing', company: 'Elite Plumbing Co.', trade: 'Plumbing', rating: 5.0, jobsCompleted: 5, initials: 'EP', isPreferred: true },
  { id: 'v3', name: 'Wilson Electric', company: 'Wilson Electric', trade: 'Electrical', rating: 4.8, jobsCompleted: 3, initials: 'WE' },
  { id: 'v4', name: 'Crystal Clear Pools', company: 'Crystal Clear Pool Service', trade: 'Pool', rating: 4.7, jobsCompleted: 12, initials: 'CC', isPreferred: true },
  { id: 'v5', name: 'ABC Roofing', company: 'ABC Roofing Inc.', trade: 'Roofing', rating: 4.6, jobsCompleted: 2, initials: 'AR' },
];

const MOCK_HISTORY: ServiceRecord[] = [
  {
    id: 's1',
    assetId: 'roof',
    assetName: 'Roof System',
    date: new Date(2024, 10, 15),
    vendor: 'ABC Roofing',
    serviceType: 'Annual Inspection',
    description: 'Complete roof inspection. All shingles in good condition. Minor gutter cleaning performed.',
    cost: 150,
    invoiceUrl: '/invoices/roof-2024.pdf',
    scheduledBy: 'Sarah',
    diy: false,
  },
  {
    id: 's2',
    assetId: 'water-heater',
    assetName: 'Water Heater',
    date: new Date(2024, 9, 5),
    vendor: 'Elite Plumbing Co.',
    vendorId: 'v2',
    serviceType: 'Annual Flush',
    description: 'Flushed sediment, checked anode rod (50% remaining), inspected connections.',
    cost: 125,
    invoiceUrl: '/invoices/waterheater-2024.pdf',
    scheduledBy: 'Sarah',
    diy: false,
  },
  {
    id: 's3',
    assetId: 'pool-pump',
    assetName: 'Pool Equipment',
    date: new Date(2024, 8, 20),
    vendor: 'Crystal Clear Pool Service',
    vendorId: 'v4',
    serviceType: 'Quarterly Service',
    description: 'Chemical balance, filter cleaning, pump inspection. Replaced O-ring seal.',
    cost: 175,
    invoiceUrl: '/invoices/pool-q3-2024.pdf',
    scheduledBy: 'Sarah',
    diy: false,
  },
  {
    id: 's4',
    assetId: 'water-softener',
    assetName: 'Water Softener',
    date: new Date(2024, 7, 30),
    serviceType: 'Salt Refill',
    description: 'Added 80lbs Morton salt pellets.',
    cost: 35,
    scheduledBy: 'Homeowner',
    diy: true,
  },
  {
    id: 's5',
    assetId: 'refrigerator',
    assetName: 'Kitchen Refrigerator',
    date: new Date(2024, 5, 15),
    vendor: 'Sub-Zero Authorized Service',
    serviceType: 'Annual Maintenance',
    description: 'Condenser coil cleaning, door seal inspection, temperature calibration.',
    cost: 250,
    invoiceUrl: '/invoices/subzero-2024.pdf',
    scheduledBy: 'Auto',
    diy: false,
  },
  {
    id: 's6',
    assetId: 'hvac-main',
    assetName: 'Main HVAC System',
    date: new Date(2024, 3, 10),
    vendor: 'AirFlow HVAC',
    vendorId: 'v1',
    serviceType: 'Spring Tune-Up',
    description: 'Full system inspection, filter replacement, coil cleaning, refrigerant check.',
    cost: 189,
    invoiceUrl: '/invoices/hvac-spring-2024.pdf',
    scheduledBy: 'Sarah',
    diy: false,
  },
];

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function getAssetIcon(type?: string, category?: string): typeof Thermometer {
  const typeOrCat = (type || category || '').toUpperCase();
  if (typeOrCat.includes('HVAC') || typeOrCat.includes('AIR') || typeOrCat.includes('CLIMATE')) return AirVent;
  if (typeOrCat.includes('PLUMBING') || typeOrCat.includes('WATER')) return Droplets;
  if (typeOrCat.includes('HEATING') || typeOrCat.includes('HEATER')) return Flame;
  if (typeOrCat.includes('ELECTRICAL')) return Zap;
  if (typeOrCat.includes('ROOF') || typeOrCat.includes('STRUCTURE')) return Home;
  if (typeOrCat.includes('POOL')) return Waves;
  if (typeOrCat.includes('REFRIGERATOR')) return Refrigerator;
  if (typeOrCat.includes('WASHER') || typeOrCat.includes('LAUNDRY')) return WashingMachine;
  return Wrench;
}

function mapAssetHealth(status?: string): AssetHealth {
  const statusUpper = (status || '').toUpperCase();
  if (statusUpper.includes('CRITICAL') || statusUpper.includes('FAILED')) return 'critical';
  if (statusUpper.includes('NEEDS_SERVICE') || statusUpper.includes('ATTENTION')) return 'needs_attention';
  if (statusUpper.includes('FAIR') || statusUpper.includes('AGING')) return 'fair';
  if (statusUpper.includes('GOOD') || statusUpper.includes('OK')) return 'good';
  return 'excellent';
}

function mapApiVendorToUi(apiVendor: Record<string, unknown>): TrustedVendor {
  const name = String(apiVendor.name || apiVendor.displayName || 'Unknown');
  const nameParts = name.split(' ').filter(Boolean);
  const initials = nameParts.length >= 2
    ? `${nameParts[0]?.charAt(0) || ''}${nameParts[nameParts.length - 1]?.charAt(0) || ''}`.toUpperCase()
    : name.substring(0, 2).toUpperCase();

  return {
    id: String(apiVendor.id),
    name: name,
    company: String(apiVendor.company || apiVendor.businessName || name),
    trade: String(apiVendor.trade || apiVendor.category || 'General'),
    initials,
    rating: Number(apiVendor.rating || 5),
    jobsCompleted: Number(apiVendor.jobsCompleted || 0),
  };
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Manager Summary Card - Shows Sarah is proactively managing
function ManagerSummaryCard({
  activeAlerts,
  scheduledServices,
}: {
  activeAlerts: number;
  scheduledServices: number;
}) {
  return (
    <div className="bg-gradient-to-br from-emerald-600 to-emerald-700 rounded-xl p-4 text-white">
      <div className="flex items-center gap-3">
        <div className="relative">
          <div className="w-12 h-12 rounded-full bg-white/20 flex items-center justify-center">
            <Headphones className="w-6 h-6" />
          </div>
          <div className="absolute -bottom-0.5 -right-0.5 w-4 h-4 bg-emerald-400 rounded-full flex items-center justify-center">
            <Check className="w-2.5 h-2.5 text-white" />
          </div>
        </div>
        <div className="flex-1">
          <p className="font-semibold">{HOUSING_MANAGER.name} is managing your home</p>
          <p className="text-emerald-100 text-sm">
            {activeAlerts > 0 ? `${activeAlerts} items being handled • ` : ''}
            {scheduledServices} upcoming services
          </p>
        </div>
      </div>
    </div>
  );
}

// Active Alert Card - Shows what manager is doing
function ActiveAlertCard({ alert }: { alert: MaintenanceAlert }) {
  const config = alertConfig[alert.severity];
  const AlertIcon = config.icon;

  const getStatusEmoji = () => {
    switch (alert.managerStatus) {
      case 'scheduling': return '📅';
      case 'ordered': return '📦';
      case 'scheduled': return '✅';
      case 'completed': return '✓';
      default: return '👀';
    }
  };

  return (
    <div className={`p-4 rounded-xl border ${config.bgColor} ${config.borderColor}`}>
      <div className="flex items-start gap-3">
        <AlertIcon className={`w-5 h-5 ${config.color} flex-shrink-0 mt-0.5`} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <p className={`font-medium ${config.color}`}>{alert.message}</p>
            {alert.daysOverdue && (
              <span className="text-xs font-medium text-red-700 bg-red-100 px-2 py-0.5 rounded-full">
                +{alert.daysOverdue} days
              </span>
            )}
          </div>
          <p className="text-sm text-warm-600 mb-2">{alert.assetName}</p>
          <div className="flex items-center gap-2 text-sm">
            <span>{getStatusEmoji()}</span>
            <span className="text-emerald-700 font-medium">{alert.managerMessage}</span>
          </div>
        </div>
      </div>
    </div>
  );
}

// Upcoming Service Card
function UpcomingServiceCard({ services }: { services: ScheduledService[] }) {
  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  return (
    <div className="bg-white rounded-xl border border-warm-200 overflow-hidden">
      <div className="p-4 border-b border-warm-200 flex items-center gap-2">
        <Calendar className="w-5 h-5 text-emerald-600" />
        <h3 className="font-semibold text-warm-900">Upcoming Service</h3>
        <span className="text-sm text-warm-500">Auto-scheduled by {HOUSING_MANAGER.name}</span>
      </div>
      <div className="divide-y divide-warm-100">
        {services.map((service) => (
          <div key={service.id} className="flex items-center gap-4 px-4 py-3">
            <div className="w-16 text-center">
              <p className="text-sm font-medium text-warm-900">{formatDate(service.date)}</p>
            </div>
            <div className="flex-1">
              <p className="font-medium text-warm-900">{service.serviceType}</p>
              <p className="text-sm text-warm-500">{service.assetName}</p>
            </div>
            <div className="text-right">
              <p className="text-sm text-warm-700">{service.vendorName}</p>
              {service.isConfirmed ? (
                <span className="text-xs text-emerald-600">✓ Confirmed</span>
              ) : (
                <span className="text-xs text-amber-600">Pending confirmation</span>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// Warranty Alert Card
function WarrantyAlertCard({
  alert,
  onApprove,
  onSkip,
}: {
  alert: WarrantyAlert;
  onApprove: () => void;
  onSkip: () => void;
}) {
  return (
    <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
      <div className="flex items-start gap-3 mb-3">
        <Shield className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
        <div>
          <h4 className="font-medium text-blue-800">Warranty Expiring Soon</h4>
          <p className="text-sm text-blue-700 mt-1">
            {alert.assetName} warranty expires {alert.expiresAt.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })} ({alert.monthsRemaining} months)
          </p>
          <p className="text-sm text-blue-600 mt-2">
            <strong>{HOUSING_MANAGER.name}&apos;s recommendation:</strong> {alert.recommendation}
          </p>
        </div>
      </div>
      <div className="flex gap-2 ml-8">
        <button
          onClick={onApprove}
          className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors"
        >
          Approve inspection
        </button>
        <button
          onClick={onSkip}
          className="px-4 py-2 border border-blue-300 text-blue-700 text-sm font-medium rounded-lg hover:bg-blue-100 transition-colors"
        >
          Skip - I&apos;ll risk it
        </button>
      </div>
    </div>
  );
}

// Handyman Visit Card
function HandymanVisitCard({
  visit,
  onViewPhotos,
  onRequestQuote,
}: {
  visit: HandymanVisit;
  onViewPhotos: () => void;
  onRequestQuote: (item: string) => void;
}) {
  return (
    <div className="bg-white rounded-xl border border-warm-200 overflow-hidden">
      <div className="p-4 border-b border-warm-200 flex items-center gap-3">
        <ClipboardCheck className="w-5 h-5 text-emerald-600" />
        <h3 className="font-semibold text-warm-900">Recent Handyman Visit</h3>
        <span className="text-sm text-warm-500">
          {visit.date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
        </span>
      </div>
      <div className="p-4">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center overflow-hidden">
            {visit.handymanAvatar ? (
              <Image src={visit.handymanAvatar} alt={visit.handymanName} width={40} height={40} className="object-cover" />
            ) : (
              <UserCheck className="w-5 h-5 text-emerald-600" />
            )}
          </div>
          <div>
            <p className="font-medium text-warm-900">{visit.handymanName} completed monthly maintenance:</p>
          </div>
        </div>

        <div className="space-y-2 mb-4">
          {visit.tasksCompleted.map((task, idx) => (
            <div key={idx} className="flex items-center gap-2 text-sm">
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
              <span className="text-warm-700">{task}</span>
            </div>
          ))}
        </div>

        {visit.notes && (
          <div className="bg-amber-50 border border-amber-200 rounded-lg p-3 mb-4">
            <p className="text-sm text-amber-800">
              <strong>Notes:</strong> &quot;{visit.notes}&quot;
            </p>
          </div>
        )}

        <div className="flex gap-2">
          {visit.photos && visit.photos.length > 0 && (
            <button
              onClick={onViewPhotos}
              className="flex items-center gap-2 px-3 py-2 border border-warm-200 text-warm-700 text-sm font-medium rounded-lg hover:bg-warm-50 transition-colors"
            >
              <Camera className="w-4 h-4" />
              View photos
            </button>
          )}
          {visit.recommendations?.map((rec, idx) => (
            <button
              key={idx}
              onClick={() => onRequestQuote(rec.item)}
              className="flex items-center gap-2 px-3 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition-colors"
            >
              Request {rec.action.toLowerCase()}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// Asset Card - Simplified, manager-focused
function AssetCard({
  asset,
  onClick,
}: {
  asset: HomeAsset;
  onClick: () => void;
}) {
  const AssetIcon = asset.icon;
  const healthStyle = healthConfig[asset.health];
  const ageYears = Math.floor((Date.now() - asset.installDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000));
  const agePercent = Math.min(100, (ageYears / asset.expectedLifespan) * 100);
  const isOverdue = asset.nextServiceDue && asset.nextServiceDue.getTime() < Date.now();

  return (
    <div
      className={`bg-white rounded-xl shadow-sm border overflow-hidden cursor-pointer hover:shadow-md transition-shadow ${
        isOverdue ? 'border-red-300' : 'border-warm-200'
      }`}
      onClick={onClick}
    >
      <div className="p-4">
        <div className="flex items-start justify-between mb-3">
          <div className="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center">
            <AssetIcon className="w-6 h-6 text-emerald-600" />
          </div>
          <span className={`text-xs font-medium px-2 py-1 rounded-full ${healthStyle.bgColor} ${healthStyle.color}`}>
            {healthStyle.label}
          </span>
        </div>
        <h3 className="font-semibold text-warm-900">{asset.name}</h3>
        <p className="text-sm text-warm-500">{asset.brand} {asset.model && `• ${asset.model}`}</p>
      </div>

      {/* Lifespan Bar */}
      <div className="px-4 pb-3">
        <div className="flex items-center justify-between text-xs text-warm-500 mb-1">
          <span>Lifespan</span>
          <span>Year {ageYears} of {asset.expectedLifespan}</span>
        </div>
        <div className="w-full bg-warm-100 rounded-full h-2">
          <div
            className={`h-2 rounded-full transition-all ${
              agePercent > 80 ? 'bg-red-500' : agePercent > 60 ? 'bg-amber-500' : 'bg-emerald-500'
            }`}
            style={{ width: `${agePercent}%` }}
          />
        </div>
      </div>

      {/* Manager-focused footer */}
      <div className={`px-4 py-3 border-t ${isOverdue ? 'bg-red-50 border-red-200' : 'bg-warm-50 border-warm-100'}`}>
        <div className="space-y-1">
          {asset.lastServiceVendor && (
            <p className="text-xs text-warm-500">
              Last serviced by {asset.lastServiceVendor}
            </p>
          )}
          <p className={`text-sm ${isOverdue ? 'text-red-700 font-medium' : 'text-warm-600'}`}>
            {isOverdue
              ? `${HOUSING_MANAGER.name} is scheduling service`
              : asset.nextServiceMonth
              ? `Next service: ${HOUSING_MANAGER.name} will schedule for ${asset.nextServiceMonth}`
              : 'No service scheduled'}
          </p>
        </div>
      </div>
    </div>
  );
}

// Verified Vendors Section
function VerifiedVendorsSection({ vendors }: { vendors: TrustedVendor[] }) {
  const preferredVendors = vendors.filter(v => v.isPreferred);
  const otherVendors = vendors.filter(v => !v.isPreferred);

  return (
    <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-6">
      <div className="flex items-center gap-2 mb-4">
        <BadgeCheck className="w-5 h-5 text-emerald-600" />
        <h2 className="font-semibold text-warm-900">Your Verified Vendors</h2>
      </div>
      <p className="text-sm text-warm-500 mb-4">
        {HOUSING_MANAGER.name} has relationships with {vendors.length} verified vendors for your home.
        All scheduling and coordination goes through Haven.
      </p>

      {preferredVendors.length > 0 && (
        <div className="mb-4">
          <p className="text-xs font-medium text-warm-500 uppercase mb-2">Preferred</p>
          <div className="grid grid-cols-2 gap-2">
            {preferredVendors.map((vendor) => (
              <div key={vendor.id} className="flex items-center gap-3 p-3 bg-emerald-50 border border-emerald-200 rounded-lg">
                <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-xs font-semibold text-emerald-700">{vendor.initials}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-warm-900 text-sm truncate">{vendor.company}</p>
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-warm-500">{vendor.trade}</span>
                    <div className="flex items-center gap-0.5 text-amber-500">
                      <Star className="w-3 h-3 fill-current" />
                      <span className="text-xs">{vendor.rating}</span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {otherVendors.length > 0 && (
        <div>
          <p className="text-xs font-medium text-warm-500 uppercase mb-2">Other Vendors ({otherVendors.length})</p>
          <div className="flex flex-wrap gap-2">
            {otherVendors.map((vendor) => (
              <span key={vendor.id} className="px-3 py-1.5 bg-warm-100 text-warm-600 text-sm rounded-full">
                {vendor.company}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// Service History Section
function ServiceHistorySection({
  history,
  assets,
}: {
  history: ServiceRecord[];
  assets: HomeAsset[];
}) {
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const [expanded, setExpanded] = useState<Set<string>>(new Set());

  const filteredHistory = useMemo(() => {
    let filtered = history;
    if (filter !== 'all') {
      filtered = filtered.filter(s => s.assetId === filter);
    }
    if (search) {
      const searchLower = search.toLowerCase();
      filtered = filtered.filter(s =>
        s.assetName.toLowerCase().includes(searchLower) ||
        s.serviceType.toLowerCase().includes(searchLower) ||
        s.vendor?.toLowerCase().includes(searchLower)
      );
    }
    return filtered.sort((a, b) => b.date.getTime() - a.date.getTime());
  }, [history, filter, search]);

  const formatDate = (date: Date) => date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  const formatCurrency = (amount: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(amount);

  const toggleExpand = (id: string) => {
    setExpanded(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const getScheduledByLabel = (scheduledBy: string) => {
    switch (scheduledBy) {
      case 'Sarah': return `Scheduled by ${HOUSING_MANAGER.name}`;
      case 'Auto': return 'Auto-scheduled';
      case 'Homeowner': return 'DIY';
      default: return scheduledBy;
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Clock className="w-5 h-5 text-warm-400" />
          <h2 className="font-semibold text-warm-900">Service History</h2>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-2 mb-4">
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-warm-400" />
          <input
            type="text"
            placeholder="Search history..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-3 py-2 text-sm border border-warm-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500"
          />
        </div>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="px-3 py-2 text-sm border border-warm-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500"
        >
          <option value="all">All Assets</option>
          {assets.map(asset => (
            <option key={asset.id} value={asset.id}>{asset.name}</option>
          ))}
        </select>
      </div>

      {/* Timeline */}
      <div className="relative">
        <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-warm-200" />
        <div className="space-y-4">
          {filteredHistory.slice(0, 5).map((record) => {
            const isExpanded = expanded.has(record.id);
            return (
              <div key={record.id} className="relative pl-10">
                <div className={`absolute left-2.5 top-1 w-3 h-3 rounded-full border-2 border-white ${
                  record.diy ? 'bg-blue-500' : 'bg-emerald-500'
                }`} />

                <div className="cursor-pointer" onClick={() => toggleExpand(record.id)}>
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-medium text-warm-900">{record.serviceType}</p>
                      <p className="text-sm text-warm-500">{record.assetName}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-warm-500">{formatDate(record.date)}</p>
                      {record.cost !== undefined && (
                        <p className="text-sm font-medium text-warm-900">{formatCurrency(record.cost)}</p>
                      )}
                    </div>
                  </div>

                  {isExpanded && (
                    <div className="mt-2 p-3 bg-warm-50 rounded-lg">
                      <p className="text-sm text-warm-600 mb-2">{record.description}</p>
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          {record.vendor && (
                            <span className="text-xs text-warm-500">by {record.vendor}</span>
                          )}
                          <span className="text-xs bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded-full">
                            {getScheduledByLabel(record.scheduledBy)}
                          </span>
                        </div>
                        {record.invoiceUrl && (
                          <button className="flex items-center gap-1 text-xs text-emerald-600 hover:text-emerald-700">
                            <FileText className="w-3 h-3" />
                            Invoice
                          </button>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {filteredHistory.length === 0 && (
        <div className="text-center py-8">
          <Clock className="w-12 h-12 text-warm-300 mx-auto mb-3" />
          <p className="text-warm-600 font-medium">No service records</p>
          <p className="text-sm text-warm-500 mt-1">{HOUSING_MANAGER.name} will log all services here</p>
        </div>
      )}
    </div>
  );
}

// Asset Detail Modal
function AssetDetailModal({
  asset,
  onClose,
}: {
  asset: HomeAsset;
  onClose: () => void;
}) {
  const AssetIcon = asset.icon;
  const healthStyle = healthConfig[asset.health];
  const isOverdue = asset.nextServiceDue && asset.nextServiceDue.getTime() < Date.now();

  const formatDate = (date: Date) => date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="fixed inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white rounded-xl shadow-xl w-full max-w-lg">
          <div className="p-6 border-b border-warm-200">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 bg-emerald-100 rounded-xl flex items-center justify-center">
                  <AssetIcon className="w-7 h-7 text-emerald-600" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-warm-900">{asset.name}</h3>
                  <p className="text-sm text-warm-500">{asset.brand} {asset.model}</p>
                </div>
              </div>
              <button onClick={onClose} className="p-2 hover:bg-warm-100 rounded-lg transition-colors">
                <X className="w-5 h-5 text-warm-400" />
              </button>
            </div>
          </div>

          <div className="p-6 space-y-4">
            {/* Health Status */}
            <div className="flex items-center justify-between p-4 bg-warm-50 rounded-lg">
              <span className="text-warm-600">Health Status</span>
              <span className={`px-3 py-1 rounded-full text-sm font-medium ${healthStyle.bgColor} ${healthStyle.color}`}>
                {healthStyle.label}
              </span>
            </div>

            {/* Details Grid */}
            <div className="grid grid-cols-2 gap-4">
              <div className="p-3 bg-warm-50 rounded-lg">
                <p className="text-xs text-warm-500">Install Date</p>
                <p className="font-medium text-warm-900">{formatDate(asset.installDate)}</p>
              </div>
              <div className="p-3 bg-warm-50 rounded-lg">
                <p className="text-xs text-warm-500">Expected Lifespan</p>
                <p className="font-medium text-warm-900">{asset.expectedLifespan} years</p>
              </div>
              {asset.location && (
                <div className="p-3 bg-warm-50 rounded-lg">
                  <p className="text-xs text-warm-500">Location</p>
                  <p className="font-medium text-warm-900">{asset.location}</p>
                </div>
              )}
              {asset.warrantyExpires && (
                <div className="p-3 bg-warm-50 rounded-lg">
                  <p className="text-xs text-warm-500">Warranty Until</p>
                  <p className="font-medium text-warm-900">{formatDate(asset.warrantyExpires)}</p>
                </div>
              )}
              {asset.serialNumber && (
                <div className="p-3 bg-warm-50 rounded-lg col-span-2">
                  <p className="text-xs text-warm-500">Serial Number</p>
                  <p className="font-medium text-warm-900 font-mono">{asset.serialNumber}</p>
                </div>
              )}
            </div>

            {/* Service Info */}
            <div className="border-t border-warm-200 pt-4">
              <h4 className="font-medium text-warm-900 mb-3">Service Schedule</h4>
              <div className="space-y-2">
                {asset.lastService && (
                  <div className="flex items-center justify-between">
                    <span className="text-warm-600">Last Service</span>
                    <div className="text-right">
                      <p className="font-medium text-warm-900">{formatDate(asset.lastService)}</p>
                      {asset.lastServiceVendor && (
                        <p className="text-xs text-warm-500">by {asset.lastServiceVendor}</p>
                      )}
                    </div>
                  </div>
                )}
                <div className="flex items-center justify-between">
                  <span className="text-warm-600">Next Service</span>
                  <div className="text-right">
                    <p className={`font-medium ${isOverdue ? 'text-red-600' : 'text-warm-900'}`}>
                      {asset.nextServiceMonth || 'Not scheduled'}
                    </p>
                    <p className="text-xs text-emerald-600">{HOUSING_MANAGER.name} will schedule</p>
                  </div>
                </div>
              </div>
            </div>

            {asset.notes && (
              <div className="border-t border-warm-200 pt-4">
                <h4 className="font-medium text-warm-900 mb-2">Notes</h4>
                <p className="text-sm text-warm-600">{asset.notes}</p>
              </div>
            )}
          </div>

          <div className="p-6 border-t border-warm-200 bg-warm-50 rounded-b-xl">
            <p className="text-sm text-warm-600 text-center">
              All maintenance is scheduled and coordinated by {HOUSING_MANAGER.name}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function MaintenancePage() {
  const { currentHousehold } = useAuth();

  // State
  const [assets] = useState<HomeAsset[]>(MOCK_ASSETS);
  const [alerts] = useState<MaintenanceAlert[]>(MOCK_ALERTS);
  const [scheduledServices] = useState<ScheduledService[]>(MOCK_SCHEDULED_SERVICES);
  const [warrantyAlerts, setWarrantyAlerts] = useState<WarrantyAlert[]>(MOCK_WARRANTY_ALERTS);
  const [handymanVisits] = useState<HandymanVisit[]>(MOCK_HANDYMAN_VISITS);
  const [vendors, setVendors] = useState<TrustedVendor[]>(MOCK_VENDORS);
  const [serviceHistory] = useState<ServiceRecord[]>(MOCK_HISTORY);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedAsset, setSelectedAsset] = useState<HomeAsset | null>(null);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'info' } | null>(null);

  // Auto-generated maintenance tasks
  const [maintenanceTasks, setMaintenanceTasks] = useState<any[]>([]);
  const [taskSummary, setTaskSummary] = useState<{ total: number; overdue: number; dueSoon: number; completed: number } | null>(null);

  const showToast = (message: string, type: 'success' | 'info' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  // Load data
  const loadData = useCallback(async () => {
    if (!currentHousehold?.id) {
      setIsLoading(false);
      return;
    }

    try {
      const api = getApiClient();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || '';

      // Fetch vendors and maintenance tasks in parallel
      const [vendorsResult, tasksResponse, summaryResponse] = await Promise.allSettled([
        api.getHouseholdVendors(currentHousehold.id),
        fetch(`${apiUrl}/maintenance/household/${currentHousehold.id}`, {
          headers: { Authorization: `Bearer ${await api.getToken?.()}` },
        }),
        fetch(`${apiUrl}/maintenance/household/${currentHousehold.id}/summary`, {
          headers: { Authorization: `Bearer ${await api.getToken?.()}` },
        }),
      ]);

      if (vendorsResult.status === 'fulfilled') {
        const vendorsData = vendorsResult.value;
        if (Array.isArray(vendorsData) && vendorsData.length > 0) {
          setVendors(vendorsData.map((v) => mapApiVendorToUi(v as unknown as Record<string, unknown>)));
        }
      }

      // Load maintenance tasks
      if (tasksResponse.status === 'fulfilled' && tasksResponse.value.ok) {
        const tasks = await tasksResponse.value.json();
        setMaintenanceTasks(tasks);
      }

      // Load task summary
      if (summaryResponse.status === 'fulfilled' && summaryResponse.value.ok) {
        const summary = await summaryResponse.value.json();
        setTaskSummary(summary);
      }
    } catch (error) {
      console.error('Error loading maintenance data:', error);
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold?.id]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Computed values
  const healthScore = useMemo(() => {
    let score = 100;
    alerts.forEach(alert => {
      if (alert.severity === 'critical') score -= 15;
      else if (alert.severity === 'warning') score -= 5;
    });
    assets.forEach(asset => {
      if (asset.health === 'critical') score -= 10;
      else if (asset.health === 'needs_attention') score -= 5;
      else if (asset.health === 'fair') score -= 2;
    });
    return Math.max(0, Math.min(100, score));
  }, [alerts, assets]);

  const activeAlerts = useMemo(() =>
    alerts.filter(a => a.severity !== 'success')
  , [alerts]);

  const getHealthScoreColor = (score: number) => {
    if (score >= 90) return 'text-emerald-600';
    if (score >= 70) return 'text-green-600';
    if (score >= 50) return 'text-yellow-600';
    if (score >= 30) return 'text-orange-600';
    return 'text-red-600';
  };

  const getHealthScoreStroke = (score: number) => {
    if (score >= 90) return '#059669';
    if (score >= 70) return '#16a34a';
    if (score >= 50) return '#ca8a04';
    if (score >= 30) return '#ea580c';
    return '#dc2626';
  };

  const radius = 80;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (healthScore / 100) * circumference;

  // Handlers
  const handleApproveWarrantyInspection = (alertId: string) => {
    setWarrantyAlerts(prev => prev.filter(a => a.id !== alertId));
    showToast(`${HOUSING_MANAGER.name} will schedule the inspection`, 'success');
  };

  const handleSkipWarrantyInspection = (alertId: string) => {
    setWarrantyAlerts(prev => prev.filter(a => a.id !== alertId));
    showToast('Noted - skipping inspection', 'info');
  };

  const handleViewPhotos = () => {
    showToast('Opening photos...', 'info');
  };

  const handleRequestQuote = (item: string) => {
    showToast(`${HOUSING_MANAGER.name} will get a quote for ${item}`, 'success');
  };

  return (
    <div className="space-y-6 pb-20 max-w-6xl mx-auto">
      {/* Toast */}
      {toast && (
        <div className="fixed top-4 right-4 z-50 animate-in slide-in-from-top duration-300">
          <div className={`flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg ${
            toast.type === 'success' ? 'bg-emerald-600 text-white' : 'bg-warm-800 text-white'
          }`}>
            {toast.type === 'success' ? <CheckCircle2 className="w-5 h-5" /> : <AlertCircle className="w-5 h-5" />}
            <span className="font-medium">{toast.message}</span>
          </div>
        </div>
      )}

      {/* Header */}
      <div>
        <h1 className="text-2xl lg:text-3xl font-bold text-warm-900">Home Maintenance</h1>
        <p className="text-warm-500 mt-1">We fix it before it breaks. {HOUSING_MANAGER.name} handles all scheduling.</p>
      </div>

      {/* Manager Summary */}
      <ManagerSummaryCard
        activeAlerts={activeAlerts.length}
        scheduledServices={scheduledServices.length}
      />

      {/* Health Score + Active Items */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Health Score Gauge */}
        <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-6 flex flex-col items-center">
          <div className="relative">
            {isLoading ? (
              <div className="w-48 h-48 flex items-center justify-center">
                <Loader2 className="w-12 h-12 text-emerald-600 animate-spin" />
              </div>
            ) : (
              <svg className="w-48 h-48 transform -rotate-90">
                <circle cx="96" cy="96" r={radius} stroke="#e2e8f0" strokeWidth="16" fill="none" />
                <circle
                  cx="96" cy="96" r={radius}
                  stroke={getHealthScoreStroke(healthScore)}
                  strokeWidth="16"
                  fill="none"
                  strokeLinecap="round"
                  strokeDasharray={circumference}
                  strokeDashoffset={strokeDashoffset}
                  className="transition-all duration-1000"
                />
              </svg>
            )}
            {!isLoading && (
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <Activity className={`w-6 h-6 ${getHealthScoreColor(healthScore)} mb-1`} />
                <span className={`text-4xl font-bold ${getHealthScoreColor(healthScore)}`}>{healthScore}</span>
                <span className="text-sm text-warm-500">Home Health</span>
              </div>
            )}
          </div>
          <p className="text-sm text-warm-500 mt-4 text-center">
            {healthScore >= 90 ? 'Your home is in excellent condition!' :
             healthScore >= 70 ? 'A few items being handled.' :
             healthScore >= 50 ? 'Several maintenance tasks in progress.' :
             'Multiple items need attention.'}
          </p>
        </div>

        {/* Active Items */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="font-semibold text-warm-900">Active Items ({activeAlerts.length})</h3>
          {activeAlerts.map(alert => (
            <ActiveAlertCard key={alert.id} alert={alert} />
          ))}
          {activeAlerts.length === 0 && (
            <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4 text-center">
              <CheckCircle2 className="w-8 h-8 text-emerald-600 mx-auto mb-2" />
              <p className="font-medium text-emerald-800">All caught up!</p>
              <p className="text-sm text-emerald-600">No active maintenance issues</p>
            </div>
          )}
        </div>
      </div>

      {/* Upcoming Services */}
      {scheduledServices.length > 0 && (
        <UpcomingServiceCard services={scheduledServices} />
      )}

      {/* Auto-Generated Maintenance Calendar */}
      {maintenanceTasks.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <div className="flex items-center gap-2">
                <Calendar className="w-5 h-5 text-emerald-600" />
                <h2 className="font-semibold text-warm-900">Maintenance Calendar</h2>
              </div>
              <p className="text-sm text-warm-500 mt-1">
                {taskSummary?.total || maintenanceTasks.length} tasks identified for your home
              </p>
            </div>
            {taskSummary && (
              <div className="flex items-center gap-4 text-sm">
                {taskSummary.dueSoon > 0 && (
                  <div className="flex items-center gap-1.5 text-amber-600">
                    <Clock className="w-4 h-4" />
                    <span>{taskSummary.dueSoon} due soon</span>
                  </div>
                )}
                {taskSummary.overdue > 0 && (
                  <div className="flex items-center gap-1.5 text-red-600">
                    <AlertTriangle className="w-4 h-4" />
                    <span>{taskSummary.overdue} overdue</span>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Summary Cards */}
          {taskSummary && (
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
              <div className="bg-warm-50 rounded-lg p-4 text-center">
                <p className="text-2xl font-bold text-warm-900">{taskSummary.total}</p>
                <p className="text-sm text-warm-500">Total Tasks</p>
              </div>
              <div className="bg-amber-50 rounded-lg p-4 text-center">
                <p className="text-2xl font-bold text-amber-600">{taskSummary.dueSoon}</p>
                <p className="text-sm text-warm-500">Due Soon</p>
              </div>
              <div className="bg-red-50 rounded-lg p-4 text-center">
                <p className="text-2xl font-bold text-red-600">{taskSummary.overdue}</p>
                <p className="text-sm text-warm-500">Overdue</p>
              </div>
              <div className="bg-emerald-50 rounded-lg p-4 text-center">
                <p className="text-2xl font-bold text-emerald-600">{taskSummary.completed}</p>
                <p className="text-sm text-warm-500">Completed</p>
              </div>
            </div>
          )}

          {/* Task List */}
          <div className="space-y-3">
            {maintenanceTasks.slice(0, 6).map((task) => {
              const isOverdue = task.nextDueDate && new Date(task.nextDueDate) < new Date() && task.status !== 'COMPLETED';
              const isDueSoon = task.status === 'DUE_SOON' || (task.nextDueDate && new Date(task.nextDueDate) < new Date(Date.now() + 30 * 24 * 60 * 60 * 1000));

              const categoryColors: Record<string, string> = {
                HVAC: 'bg-orange-100 text-orange-700',
                POOL: 'bg-cyan-100 text-cyan-700',
                PLUMBING: 'bg-blue-100 text-blue-700',
                CHIMNEY: 'bg-amber-100 text-amber-700',
                ROOFING: 'bg-gray-100 text-gray-700',
                EXTERIOR: 'bg-green-100 text-green-700',
                LANDSCAPING: 'bg-emerald-100 text-emerald-700',
                SAFETY: 'bg-red-100 text-red-700',
                SEASONAL: 'bg-purple-100 text-purple-700',
                APPLIANCES: 'bg-indigo-100 text-indigo-700',
              };

              return (
                <div
                  key={task.id}
                  className={`flex items-center justify-between p-4 rounded-lg border ${
                    isOverdue ? 'border-red-200 bg-red-50' : 'border-warm-200 bg-warm-50'
                  }`}
                >
                  <div className="flex items-center gap-4">
                    <div className={`px-2 py-1 rounded text-xs font-medium ${categoryColors[task.category] || 'bg-warm-100 text-warm-700'}`}>
                      {task.category}
                    </div>
                    <div>
                      <p className="font-medium text-warm-900">{task.title}</p>
                      <div className="flex items-center gap-3 text-sm text-warm-500">
                        <span>{task.frequency?.replace('_', ' ')}</span>
                        {task.seasonalTiming && task.seasonalTiming !== 'ANY' && (
                          <span className="capitalize">{task.seasonalTiming.toLowerCase()}</span>
                        )}
                        {task.estimatedCost > 0 && (
                          <span>~${task.estimatedCost}</span>
                        )}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    {task.nextDueDate && (
                      <div className={`text-sm ${isOverdue ? 'text-red-600 font-medium' : isDueSoon ? 'text-amber-600' : 'text-warm-500'}`}>
                        {isOverdue ? 'Overdue' : new Date(task.nextDueDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                      </div>
                    )}
                    {task.priority === 'HIGH' && !isOverdue && (
                      <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded">High Priority</span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>

          {maintenanceTasks.length > 6 && (
            <div className="mt-4 text-center">
              <button className="text-sm text-emerald-600 hover:text-emerald-700 font-medium">
                View all {maintenanceTasks.length} tasks
              </button>
            </div>
          )}
        </div>
      )}

      {/* Warranty Alerts */}
      {warrantyAlerts.map(alert => (
        <WarrantyAlertCard
          key={alert.id}
          alert={alert}
          onApprove={() => handleApproveWarrantyInspection(alert.id)}
          onSkip={() => handleSkipWarrantyInspection(alert.id)}
        />
      ))}

      {/* Recent Handyman Visit */}
      {handymanVisits.length > 0 && handymanVisits[0] && (
        <HandymanVisitCard
          visit={handymanVisits[0]}
          onViewPhotos={handleViewPhotos}
          onRequestQuote={handleRequestQuote}
        />
      )}

      {/* Assets Grid */}
      <div>
        <div className="flex items-center gap-2 mb-4">
          <Settings className="w-5 h-5 text-warm-400" />
          <h2 className="font-semibold text-warm-900">Your Home Systems</h2>
          <span className="text-sm text-warm-500">({assets.length})</span>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {assets.map((asset) => (
            <AssetCard
              key={asset.id}
              asset={asset}
              onClick={() => setSelectedAsset(asset)}
            />
          ))}
        </div>
      </div>

      {/* Bottom Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Verified Vendors */}
        <VerifiedVendorsSection vendors={vendors} />

        {/* Service History */}
        <ServiceHistorySection history={serviceHistory} assets={assets} />
      </div>

      {/* Asset Detail Modal */}
      {selectedAsset && (
        <AssetDetailModal
          asset={selectedAsset}
          onClose={() => setSelectedAsset(null)}
        />
      )}
    </div>
  );
}

// Export for API mapping when available
export { getAssetIcon, mapAssetHealth, mapApiVendorToUi };
