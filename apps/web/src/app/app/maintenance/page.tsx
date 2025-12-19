'use client';

import { useState, useMemo } from 'react';
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
  Phone,
  MessageCircle,
  Star,
  Plus,
  FileText,
  Search,
  Wrench,
  Settings,
  RefreshCw,
  X,
  Camera,
  Activity,
  Waves,
  Refrigerator,
  WashingMachine,
  AirVent,
  BadgeCheck,
  ExternalLink,
} from 'lucide-react';

// Types
type AssetHealth = 'excellent' | 'good' | 'fair' | 'needs_attention' | 'critical';
type AlertSeverity = 'critical' | 'warning' | 'info' | 'success';

interface HomeAsset {
  id: string;
  name: string;
  category: string;
  brand: string;
  model?: string;
  icon: typeof Thermometer;
  installDate: Date;
  expectedLifespan: number; // years
  lastService?: Date;
  nextServiceDue?: Date;
  health: AssetHealth;
  location?: string;
  warrantyExpires?: Date;
  notes?: string;
}

interface MaintenanceAlert {
  id: string;
  assetId?: string;
  assetName: string;
  message: string;
  severity: AlertSeverity;
  daysOverdue?: number;
  dueDate?: Date;
}

interface TrustedVendor {
  id: string;
  name: string;
  company: string;
  trade: string;
  phone: string;
  email: string;
  avatar?: string;
  initials: string;
  lastVisit?: Date;
  rating: number;
  jobsCompleted: number;
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
  notes?: string;
  diy: boolean;
}

// Mock Data
const mockAssets: HomeAsset[] = [
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
    nextServiceDue: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000), // 14 days overdue
    health: 'needs_attention',
    location: 'Attic',
    warrantyExpires: new Date(2029, 5, 15),
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
    nextServiceDue: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
    health: 'good',
    location: 'Garage',
    warrantyExpires: new Date(2026, 8, 22),
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
    nextServiceDue: new Date(Date.now() + 335 * 24 * 60 * 60 * 1000),
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
    nextServiceDue: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    health: 'good',
    location: 'Backyard',
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
    nextServiceDue: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
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
    nextServiceDue: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 2 weeks
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
    nextServiceDue: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
    health: 'excellent',
    location: 'Kitchen',
    warrantyExpires: new Date(2025, 6, 1),
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
    nextServiceDue: new Date(Date.now() + 150 * 24 * 60 * 60 * 1000),
    health: 'excellent',
    location: 'Laundry Room',
    warrantyExpires: new Date(2026, 0, 20),
  },
];

const mockAlerts: MaintenanceAlert[] = [
  {
    id: 'a1',
    assetId: 'hvac-main',
    assetName: 'Main HVAC System',
    message: 'HVAC Service Overdue',
    severity: 'critical',
    daysOverdue: 14,
  },
  {
    id: 'a2',
    assetId: 'water-softener',
    assetName: 'Water Softener',
    message: 'Water filter expires in 2 weeks',
    severity: 'warning',
    dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'a3',
    assetId: 'roof',
    assetName: 'Roof System',
    message: 'Annual inspection completed',
    severity: 'success',
  },
  {
    id: 'a4',
    assetName: 'Smoke Detectors',
    message: 'Battery replacement due next month',
    severity: 'info',
    dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
  },
];

const mockVendors: TrustedVendor[] = [
  {
    id: 'v1',
    name: 'Mike Thompson',
    company: 'Thompson HVAC Services',
    trade: 'HVAC',
    phone: '(512) 555-0201',
    email: 'mike@thompsonhvac.com',
    initials: 'MT',
    lastVisit: new Date(2024, 3, 10),
    rating: 4.9,
    jobsCompleted: 8,
  },
  {
    id: 'v2',
    name: 'Sarah Martinez',
    company: 'Elite Plumbing Co.',
    trade: 'Plumber',
    phone: '(512) 555-0202',
    email: 'sarah@eliteplumbing.com',
    initials: 'SM',
    lastVisit: new Date(2024, 9, 5),
    rating: 5.0,
    jobsCompleted: 5,
  },
  {
    id: 'v3',
    name: 'James Wilson',
    company: 'Wilson Electric',
    trade: 'Electrician',
    phone: '(512) 555-0203',
    email: 'james@wilsonelectric.com',
    initials: 'JW',
    lastVisit: new Date(2023, 11, 12),
    rating: 4.8,
    jobsCompleted: 3,
  },
  {
    id: 'v4',
    name: 'Crystal Clear Pools',
    company: 'Crystal Clear Pool Service',
    trade: 'Pool',
    phone: '(512) 555-0204',
    email: 'service@crystalclearpools.com',
    initials: 'CC',
    lastVisit: new Date(2024, 8, 20),
    rating: 4.7,
    jobsCompleted: 12,
  },
];

const mockServiceHistory: ServiceRecord[] = [
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
    diy: false,
  },
  {
    id: 's6',
    assetId: 'hvac-main',
    assetName: 'Main HVAC System',
    date: new Date(2024, 3, 10),
    vendor: 'Thompson HVAC Services',
    vendorId: 'v1',
    serviceType: 'Spring Tune-Up',
    description: 'Full system inspection, filter replacement, coil cleaning, refrigerant check.',
    cost: 189,
    invoiceUrl: '/invoices/hvac-spring-2024.pdf',
    diy: false,
  },
];

// Health config
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

export default function MaintenancePage() {
  // State
  const [assets] = useState<HomeAsset[]>(mockAssets);
  const [alerts] = useState<MaintenanceAlert[]>(mockAlerts);
  const [vendors] = useState<TrustedVendor[]>(mockVendors);
  const [serviceHistory] = useState<ServiceRecord[]>(mockServiceHistory);

  // UI State
  const [selectedAsset, setSelectedAsset] = useState<HomeAsset | null>(null);
  const [showLogServiceModal, setShowLogServiceModal] = useState(false);
  const [showAssetDetailModal, setShowAssetDetailModal] = useState<HomeAsset | null>(null);
  const [historyFilter, setHistoryFilter] = useState<string>('all');
  const [historySearch, setHistorySearch] = useState('');
  const [expandedHistory, setExpandedHistory] = useState<Set<string>>(new Set());

  // Calculate overall health score
  const healthScore = useMemo(() => {
    let score = 100;

    // Deduct for overdue maintenance
    alerts.forEach(alert => {
      if (alert.severity === 'critical') {
        score -= 15;
      } else if (alert.severity === 'warning') {
        score -= 5;
      }
    });

    // Factor in asset health
    assets.forEach(asset => {
      if (asset.health === 'critical') score -= 10;
      else if (asset.health === 'needs_attention') score -= 5;
      else if (asset.health === 'fair') score -= 2;
    });

    return Math.max(0, Math.min(100, score));
  }, [alerts, assets]);

  // Get health score color
  const getHealthScoreColor = (score: number) => {
    if (score >= 90) return 'text-emerald-600';
    if (score >= 70) return 'text-green-600';
    if (score >= 50) return 'text-yellow-600';
    if (score >= 30) return 'text-orange-600';
    return 'text-red-600';
  };

  const getHealthScoreStroke = (score: number) => {
    if (score >= 90) return '#059669'; // emerald-600
    if (score >= 70) return '#16a34a'; // green-600
    if (score >= 50) return '#ca8a04'; // yellow-600
    if (score >= 30) return '#ea580c'; // orange-600
    return '#dc2626'; // red-600
  };

  // Calculate asset age percentage
  const getAssetAgePercent = (asset: HomeAsset) => {
    const ageYears = (Date.now() - asset.installDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000);
    return Math.min(100, (ageYears / asset.expectedLifespan) * 100);
  };

  // Check if service is overdue
  const isOverdue = (date?: Date) => {
    if (!date) return false;
    return date.getTime() < Date.now();
  };

  // Format helpers
  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const getDaysUntil = (date: Date) => {
    return Math.ceil((date.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
  };

  const getRelativeTime = (date: Date) => {
    const days = getDaysUntil(date);
    if (days < 0) return `${Math.abs(days)} days overdue`;
    if (days === 0) return 'Today';
    if (days === 1) return 'Tomorrow';
    if (days < 7) return `In ${days} days`;
    if (days < 30) return `In ${Math.ceil(days / 7)} weeks`;
    if (days < 365) return `In ${Math.ceil(days / 30)} months`;
    return `In ${Math.ceil(days / 365)} years`;
  };

  // Filter service history
  const filteredHistory = useMemo(() => {
    let filtered = serviceHistory;
    if (historyFilter !== 'all') {
      filtered = filtered.filter(s => s.assetId === historyFilter);
    }
    if (historySearch) {
      const search = historySearch.toLowerCase();
      filtered = filtered.filter(s =>
        s.assetName.toLowerCase().includes(search) ||
        s.serviceType.toLowerCase().includes(search) ||
        s.description.toLowerCase().includes(search) ||
        s.vendor?.toLowerCase().includes(search)
      );
    }
    return filtered.sort((a, b) => b.date.getTime() - a.date.getTime());
  }, [serviceHistory, historyFilter, historySearch]);

  // Toggle history expansion
  const toggleHistory = (id: string) => {
    setExpandedHistory(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  // Calculate circumference for SVG gauge
  const radius = 80;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (healthScore / 100) * circumference;

  return (
    <div className="space-y-6 pb-20">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Maintenance</h1>
          <p className="text-slate-600 mt-1">Proactive home health monitoring and service tracking</p>
        </div>
        <button
          onClick={() => setShowLogServiceModal(true)}
          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
        >
          <Plus className="w-5 h-5" />
          Log Service
        </button>
      </div>

      {/* Health Score Dashboard */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div className="flex flex-col lg:flex-row gap-6">
          {/* Health Gauge */}
          <div className="flex flex-col items-center lg:items-start">
            <div className="relative">
              <svg className="w-48 h-48 transform -rotate-90">
                {/* Background circle */}
                <circle
                  cx="96"
                  cy="96"
                  r={radius}
                  stroke="#e2e8f0"
                  strokeWidth="16"
                  fill="none"
                />
                {/* Progress circle */}
                <circle
                  cx="96"
                  cy="96"
                  r={radius}
                  stroke={getHealthScoreStroke(healthScore)}
                  strokeWidth="16"
                  fill="none"
                  strokeLinecap="round"
                  strokeDasharray={circumference}
                  strokeDashoffset={strokeDashoffset}
                  className="transition-all duration-1000"
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <Activity className={`w-6 h-6 ${getHealthScoreColor(healthScore)} mb-1`} />
                <span className={`text-4xl font-bold ${getHealthScoreColor(healthScore)}`}>{healthScore}</span>
                <span className="text-sm text-slate-500">Home Health</span>
              </div>
            </div>
            <p className="text-sm text-slate-500 mt-2 text-center lg:text-left max-w-[200px]">
              {healthScore >= 90 ? 'Your home is in excellent condition!' :
               healthScore >= 70 ? 'A few items need attention soon.' :
               healthScore >= 50 ? 'Several maintenance tasks are due.' :
               'Multiple critical issues need immediate attention.'}
            </p>
          </div>

          {/* Alerts */}
          <div className="flex-1">
            <h3 className="font-semibold text-slate-900 mb-3">Active Alerts</h3>
            <div className="space-y-2">
              {alerts.map((alert) => {
                const config = alertConfig[alert.severity];
                const AlertIcon = config.icon;
                return (
                  <div
                    key={alert.id}
                    className={`flex items-center gap-3 p-3 rounded-lg border ${config.bgColor} ${config.borderColor}`}
                  >
                    <AlertIcon className={`w-5 h-5 ${config.color} flex-shrink-0`} />
                    <div className="flex-1 min-w-0">
                      <p className={`font-medium ${config.color}`}>{alert.message}</p>
                      <p className="text-sm text-slate-600">{alert.assetName}</p>
                    </div>
                    {alert.daysOverdue && (
                      <span className="text-xs font-medium text-red-700 bg-red-100 px-2 py-1 rounded-full">
                        +{alert.daysOverdue} days
                      </span>
                    )}
                    {alert.severity !== 'success' && (
                      <button className="text-sm font-medium text-emerald-600 hover:text-emerald-700 whitespace-nowrap">
                        Take Action
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* My Assets Grid */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Settings className="w-5 h-5 text-slate-400" />
            <h2 className="font-semibold text-slate-900">My Assets</h2>
            <span className="text-sm text-slate-500">({assets.length})</span>
          </div>
          <button className="text-sm text-emerald-600 font-medium hover:text-emerald-700">
            + Add Asset
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {assets.map((asset) => {
            const AssetIcon = asset.icon;
            const agePercent = getAssetAgePercent(asset);
            const overdue = isOverdue(asset.nextServiceDue);
            const healthStyle = healthConfig[asset.health];

            return (
              <div
                key={asset.id}
                className={`bg-white rounded-xl shadow-sm border overflow-hidden cursor-pointer hover:shadow-md transition-shadow ${
                  overdue ? 'border-red-300' : 'border-slate-200'
                }`}
                onClick={() => setShowAssetDetailModal(asset)}
              >
                {/* Header */}
                <div className="p-4">
                  <div className="flex items-start justify-between mb-3">
                    <div className="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center">
                      <AssetIcon className="w-6 h-6 text-emerald-600" />
                    </div>
                    <span className={`text-xs font-medium px-2 py-1 rounded-full ${healthStyle.bgColor} ${healthStyle.color}`}>
                      {healthStyle.label}
                    </span>
                  </div>
                  <h3 className="font-semibold text-slate-900">{asset.name}</h3>
                  <p className="text-sm text-slate-500">{asset.brand} {asset.model && `• ${asset.model}`}</p>
                </div>

                {/* Lifespan Bar */}
                <div className="px-4 pb-3">
                  <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
                    <span>Lifespan</span>
                    <span>Year {Math.floor(agePercent / 100 * asset.expectedLifespan)} of {asset.expectedLifespan}</span>
                  </div>
                  <div className="w-full bg-slate-100 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full transition-all ${
                        agePercent > 80 ? 'bg-red-500' :
                        agePercent > 60 ? 'bg-amber-500' :
                        'bg-emerald-500'
                      }`}
                      style={{ width: `${agePercent}%` }}
                    />
                  </div>
                </div>

                {/* Service Status */}
                <div className={`px-4 py-3 border-t ${overdue ? 'bg-red-50 border-red-200' : 'bg-slate-50 border-slate-100'}`}>
                  <div className="flex items-center justify-between text-sm">
                    <div>
                      <p className="text-slate-500">Next Service</p>
                      <p className={`font-medium ${overdue ? 'text-red-700' : 'text-slate-900'}`}>
                        {asset.nextServiceDue ? getRelativeTime(asset.nextServiceDue) : 'Not scheduled'}
                      </p>
                    </div>
                    <div className="flex gap-1">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedAsset(asset);
                          setShowLogServiceModal(true);
                        }}
                        className="p-2 text-slate-400 hover:text-emerald-600 hover:bg-white rounded-lg transition-colors"
                        title="Log Service"
                      >
                        <Wrench className="w-4 h-4" />
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          // Navigate to requests with asset pre-selected
                        }}
                        className="p-2 text-slate-400 hover:text-emerald-600 hover:bg-white rounded-lg transition-colors"
                        title="Request Pro"
                      >
                        <Phone className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Bottom Section: My Team + Service History */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* My Team (Trusted Vendors) */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <BadgeCheck className="w-5 h-5 text-emerald-600" />
              <h2 className="font-semibold text-slate-900">My Team</h2>
            </div>
            <button className="text-sm text-emerald-600 font-medium hover:text-emerald-700 flex items-center gap-1">
              Find Pros
              <ExternalLink className="w-4 h-4" />
            </button>
          </div>

          {vendors.length > 0 ? (
            <div className="space-y-3">
              {vendors.map((vendor) => (
                <div
                  key={vendor.id}
                  className="flex items-center gap-4 p-3 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors"
                >
                  <div className="w-12 h-12 bg-emerald-100 rounded-full flex items-center justify-center flex-shrink-0">
                    <span className="text-sm font-semibold text-emerald-700">{vendor.initials}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="font-medium text-slate-900">{vendor.name}</p>
                      <div className="flex items-center gap-0.5 text-amber-500">
                        <Star className="w-3 h-3 fill-current" />
                        <span className="text-xs font-medium">{vendor.rating}</span>
                      </div>
                    </div>
                    <p className="text-sm text-slate-500">{vendor.trade} • {vendor.company}</p>
                    {vendor.lastVisit && (
                      <p className="text-xs text-slate-400">Last visit: {formatDate(vendor.lastVisit)}</p>
                    )}
                  </div>
                  <div className="flex gap-1">
                    <button className="p-2 text-slate-400 hover:text-emerald-600 hover:bg-white rounded-lg transition-colors">
                      <Phone className="w-4 h-4" />
                    </button>
                    <button className="p-2 text-slate-400 hover:text-emerald-600 hover:bg-white rounded-lg transition-colors">
                      <MessageCircle className="w-4 h-4" />
                    </button>
                    <button className="p-2 text-slate-400 hover:text-emerald-600 hover:bg-white rounded-lg transition-colors">
                      <RefreshCw className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8">
              <BadgeCheck className="w-12 h-12 text-slate-300 mx-auto mb-3" />
              <p className="text-slate-600 font-medium">Build your team</p>
              <p className="text-sm text-slate-500 mt-1">Find trusted pros in the Social Directory</p>
              <button className="mt-4 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                Browse Directory
              </button>
            </div>
          )}
        </div>

        {/* Service History */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Clock className="w-5 h-5 text-slate-400" />
              <h2 className="font-semibold text-slate-900">Service History</h2>
            </div>
            <button className="text-sm text-slate-500 hover:text-slate-700">
              View All
            </button>
          </div>

          {/* Filters */}
          <div className="flex gap-2 mb-4">
            <div className="relative flex-1">
              <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                placeholder="Search history..."
                value={historySearch}
                onChange={(e) => setHistorySearch(e.target.value)}
                className="w-full pl-9 pr-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
            </div>
            <select
              value={historyFilter}
              onChange={(e) => setHistoryFilter(e.target.value)}
              className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500"
            >
              <option value="all">All Assets</option>
              {assets.map(asset => (
                <option key={asset.id} value={asset.id}>{asset.name}</option>
              ))}
            </select>
          </div>

          {/* Timeline */}
          <div className="relative">
            {/* Timeline line */}
            <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-slate-200" />

            <div className="space-y-4">
              {filteredHistory.slice(0, 5).map((record) => {
                const isExpanded = expandedHistory.has(record.id);
                return (
                  <div key={record.id} className="relative pl-10">
                    {/* Timeline dot */}
                    <div className={`absolute left-2.5 top-1 w-3 h-3 rounded-full border-2 border-white ${
                      record.diy ? 'bg-blue-500' : 'bg-emerald-500'
                    }`} />

                    <div
                      className="cursor-pointer"
                      onClick={() => toggleHistory(record.id)}
                    >
                      <div className="flex items-start justify-between">
                        <div>
                          <p className="font-medium text-slate-900">{record.serviceType}</p>
                          <p className="text-sm text-slate-500">{record.assetName}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-sm text-slate-500">{formatDate(record.date)}</p>
                          {record.cost !== undefined && (
                            <p className="text-sm font-medium text-slate-900">{formatCurrency(record.cost)}</p>
                          )}
                        </div>
                      </div>

                      {isExpanded && (
                        <div className="mt-2 p-3 bg-slate-50 rounded-lg">
                          <p className="text-sm text-slate-600 mb-2">{record.description}</p>
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                              {record.diy ? (
                                <span className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full">DIY</span>
                              ) : record.vendor && (
                                <span className="text-xs text-slate-500">by {record.vendor}</span>
                              )}
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
              <Clock className="w-12 h-12 text-slate-300 mx-auto mb-3" />
              <p className="text-slate-600 font-medium">No service records yet</p>
              <p className="text-sm text-slate-500 mt-1">Log your first service to start tracking</p>
            </div>
          )}
        </div>
      </div>

      {/* Log Service Modal */}
      {showLogServiceModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => {
              setShowLogServiceModal(false);
              setSelectedAsset(null);
            }} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-lg">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-slate-900">Log Service</h3>
                  <button
                    onClick={() => {
                      setShowLogServiceModal(false);
                      setSelectedAsset(null);
                    }}
                    className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                  >
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Asset</label>
                  <select
                    defaultValue={selectedAsset?.id || ''}
                    className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600"
                  >
                    <option value="">Select an asset...</option>
                    {assets.map(asset => (
                      <option key={asset.id} value={asset.id}>{asset.name}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Service Type</label>
                  <input
                    type="text"
                    placeholder="e.g., Filter Replacement, Annual Tune-Up"
                    className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Date</label>
                  <input
                    type="date"
                    defaultValue={new Date().toISOString().split('T')[0]}
                    className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600"
                  />
                </div>

                <div className="flex items-center gap-4">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input type="radio" name="serviceBy" value="diy" className="text-emerald-600" />
                    <span className="text-sm text-slate-700">DIY</span>
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input type="radio" name="serviceBy" value="vendor" defaultChecked className="text-emerald-600" />
                    <span className="text-sm text-slate-700">Professional</span>
                  </label>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Vendor (Optional)</label>
                  <select className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600">
                    <option value="">Select a vendor...</option>
                    {vendors.map(vendor => (
                      <option key={vendor.id} value={vendor.id}>{vendor.name} - {vendor.trade}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Cost (Optional)</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">$</span>
                    <input
                      type="number"
                      placeholder="0.00"
                      className="w-full pl-7 pr-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Notes</label>
                  <textarea
                    rows={3}
                    placeholder="Describe what was done..."
                    className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 resize-none"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Upload Invoice (Optional)</label>
                  <div className="border-2 border-dashed border-slate-300 rounded-lg p-4 text-center hover:border-emerald-500 transition-colors cursor-pointer">
                    <Camera className="w-8 h-8 text-slate-400 mx-auto mb-2" />
                    <p className="text-sm text-slate-600">Click to upload or drag and drop</p>
                    <p className="text-xs text-slate-400 mt-1">PDF, PNG, JPG up to 10MB</p>
                  </div>
                </div>
              </div>

              <div className="p-6 border-t border-slate-200 flex gap-3">
                <button
                  onClick={() => {
                    setShowLogServiceModal(false);
                    setSelectedAsset(null);
                  }}
                  className="flex-1 py-2.5 border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => {
                    setShowLogServiceModal(false);
                    setSelectedAsset(null);
                  }}
                  className="flex-1 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
                >
                  Save Service
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Asset Detail Modal */}
      {showAssetDetailModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowAssetDetailModal(null)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-lg">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-14 h-14 bg-emerald-100 rounded-xl flex items-center justify-center">
                      {(() => {
                        const AssetIcon = showAssetDetailModal.icon;
                        return <AssetIcon className="w-7 h-7 text-emerald-600" />;
                      })()}
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-slate-900">{showAssetDetailModal.name}</h3>
                      <p className="text-sm text-slate-500">{showAssetDetailModal.brand} {showAssetDetailModal.model}</p>
                    </div>
                  </div>
                  <button
                    onClick={() => setShowAssetDetailModal(null)}
                    className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                  >
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6 space-y-4">
                {/* Health Status */}
                <div className="flex items-center justify-between p-4 bg-slate-50 rounded-lg">
                  <span className="text-slate-600">Health Status</span>
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                    healthConfig[showAssetDetailModal.health].bgColor
                  } ${healthConfig[showAssetDetailModal.health].color}`}>
                    {healthConfig[showAssetDetailModal.health].label}
                  </span>
                </div>

                {/* Details Grid */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-3 bg-slate-50 rounded-lg">
                    <p className="text-xs text-slate-500">Install Date</p>
                    <p className="font-medium text-slate-900">{formatDate(showAssetDetailModal.installDate)}</p>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-lg">
                    <p className="text-xs text-slate-500">Expected Lifespan</p>
                    <p className="font-medium text-slate-900">{showAssetDetailModal.expectedLifespan} years</p>
                  </div>
                  {showAssetDetailModal.location && (
                    <div className="p-3 bg-slate-50 rounded-lg">
                      <p className="text-xs text-slate-500">Location</p>
                      <p className="font-medium text-slate-900">{showAssetDetailModal.location}</p>
                    </div>
                  )}
                  {showAssetDetailModal.warrantyExpires && (
                    <div className="p-3 bg-slate-50 rounded-lg">
                      <p className="text-xs text-slate-500">Warranty Until</p>
                      <p className="font-medium text-slate-900">{formatDate(showAssetDetailModal.warrantyExpires)}</p>
                    </div>
                  )}
                </div>

                {/* Service Status */}
                <div className="border-t border-slate-200 pt-4">
                  <h4 className="font-medium text-slate-900 mb-3">Service Schedule</h4>
                  <div className="space-y-2">
                    {showAssetDetailModal.lastService && (
                      <div className="flex items-center justify-between">
                        <span className="text-slate-600">Last Service</span>
                        <span className="font-medium text-slate-900">{formatDate(showAssetDetailModal.lastService)}</span>
                      </div>
                    )}
                    {showAssetDetailModal.nextServiceDue && (
                      <div className="flex items-center justify-between">
                        <span className="text-slate-600">Next Due</span>
                        <span className={`font-medium ${
                          isOverdue(showAssetDetailModal.nextServiceDue) ? 'text-red-600' : 'text-slate-900'
                        }`}>
                          {getRelativeTime(showAssetDetailModal.nextServiceDue)}
                        </span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Notes */}
                {showAssetDetailModal.notes && (
                  <div className="border-t border-slate-200 pt-4">
                    <h4 className="font-medium text-slate-900 mb-2">Notes</h4>
                    <p className="text-sm text-slate-600">{showAssetDetailModal.notes}</p>
                  </div>
                )}
              </div>

              <div className="p-6 border-t border-slate-200 flex gap-3">
                <button
                  onClick={() => {
                    setSelectedAsset(showAssetDetailModal);
                    setShowAssetDetailModal(null);
                    setShowLogServiceModal(true);
                  }}
                  className="flex-1 flex items-center justify-center gap-2 py-2.5 border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors"
                >
                  <Wrench className="w-5 h-5" />
                  Log Service
                </button>
                <button
                  className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
                >
                  <Phone className="w-5 h-5" />
                  Request Pro
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Mobile FAB */}
      <div className="fixed bottom-6 right-6 sm:hidden">
        <button
          onClick={() => setShowLogServiceModal(true)}
          className="w-14 h-14 bg-emerald-600 text-white rounded-full shadow-lg flex items-center justify-center hover:bg-emerald-700 transition-colors"
        >
          <Plus className="w-6 h-6" />
        </button>
      </div>
    </div>
  );
}
