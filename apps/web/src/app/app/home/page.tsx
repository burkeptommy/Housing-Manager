'use client';

import { useState } from 'react';
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
  Flame,
  Wind,
  Shield,
  Car,
  Waves,
  TreePine,
  Refrigerator,
  WashingMachine,
  Tv,
  Wifi,
  Lock,
  Camera,
  FileText,
  Upload,
  Plus,
  ChevronRight,
  ChevronDown,
  AlertCircle,
  CheckCircle2,
  Clock,
  Star,
  Phone,
  ExternalLink,
  Edit,
  MoreHorizontal,
  Pencil,
  Building,
  Key,
  Users,
  DollarSign,
  CalendarDays,
  History,
  Package,
  Settings,
  Info,
  X,
} from 'lucide-react';
import { VendorAvatar } from '@/components/ui/avatar';

// ============================================================================
// TYPES
// ============================================================================

interface PropertyInfo {
  address: string;
  city: string;
  state: string;
  zip: string;
  propertyType: string;
  yearBuilt: number;
  sqft: number;
  lotSize: string;
  bedrooms: number;
  bathrooms: number;
  garage: string;
  stories: number;
  photoUrl: string;
  purchaseDate?: string;
  purchasePrice?: number;
  currentValue?: number;
}

interface HomeSystem {
  id: string;
  name: string;
  category: 'hvac' | 'plumbing' | 'electrical' | 'appliance' | 'exterior' | 'security' | 'pool' | 'other';
  type: string;
  brand?: string;
  model?: string;
  installDate?: string;
  warrantyExpiry?: string;
  lastService?: string;
  nextService?: string;
  serviceInterval?: string;
  condition: 'excellent' | 'good' | 'fair' | 'needs-attention' | 'unknown';
  assignedVendor?: {
    name: string;
    phone: string;
    lastUsed?: string;
  };
  notes?: string;
  manualUrl?: string;
}

interface InsuranceInfo {
  provider: string;
  policyNumber: string;
  premium: number;
  premiumFrequency: string;
  deductible: number;
  coverage: number;
  expiryDate: string;
  agentName?: string;
  agentPhone?: string;
}

interface ImportantCode {
  label: string;
  value: string;
  hidden?: boolean;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const PROPERTY: PropertyInfo = {
  address: '38 Bedford Road',
  city: 'Greenwich',
  state: 'CT',
  zip: '06831',
  propertyType: 'Single Family',
  yearBuilt: 1998,
  sqft: 5200,
  lotSize: '1.2 acres',
  bedrooms: 5,
  bathrooms: 4.5,
  garage: '3-car attached',
  stories: 2,
  photoUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&h=800&fit=crop',
  purchaseDate: 'June 2019',
  purchasePrice: 2150000,
  currentValue: 2650000,
};

const HOME_SYSTEMS: HomeSystem[] = [
  // HVAC
  {
    id: 'hvac-1',
    name: 'Central Air Conditioning',
    category: 'hvac',
    type: 'Split System Central AC',
    brand: 'Carrier',
    model: 'Infinity 26',
    installDate: 'March 2021',
    warrantyExpiry: 'March 2031',
    lastService: 'October 2024',
    nextService: 'January 2025',
    serviceInterval: 'Every 3 months',
    condition: 'excellent',
    assignedVendor: {
      name: 'Comfort Zone HVAC',
      phone: '(203) 555-COOL',
      lastUsed: 'October 2024',
    },
  },
  {
    id: 'hvac-2',
    name: 'Gas Furnace',
    category: 'hvac',
    type: 'High-Efficiency Gas Furnace',
    brand: 'Carrier',
    model: 'Infinity 98',
    installDate: 'March 2021',
    warrantyExpiry: 'March 2031',
    lastService: 'October 2024',
    nextService: 'January 2025',
    serviceInterval: 'Every 3 months',
    condition: 'excellent',
    assignedVendor: {
      name: 'Comfort Zone HVAC',
      phone: '(203) 555-COOL',
      lastUsed: 'October 2024',
    },
  },
  {
    id: 'hvac-3',
    name: 'Water Heater',
    category: 'hvac',
    type: 'Tankless Gas Water Heater',
    brand: 'Rinnai',
    model: 'RU199iN',
    installDate: 'August 2020',
    warrantyExpiry: 'August 2032',
    lastService: 'August 2024',
    nextService: 'August 2025',
    serviceInterval: 'Annually',
    condition: 'good',
    assignedVendor: {
      name: "Mike's Plumbing",
      phone: '(203) 555-PIPE',
      lastUsed: 'August 2024',
    },
  },
  // Plumbing
  {
    id: 'plumb-1',
    name: 'Main Water Line',
    category: 'plumbing',
    type: 'Copper Main Line',
    installDate: '1998 (Original)',
    condition: 'good',
    assignedVendor: {
      name: "Mike's Plumbing",
      phone: '(203) 555-PIPE',
    },
    notes: 'Inspected 2023, no issues found',
  },
  {
    id: 'plumb-2',
    name: 'Sump Pump',
    category: 'plumbing',
    type: 'Submersible Sump Pump with Battery Backup',
    brand: 'Zoeller',
    model: 'M53',
    installDate: 'April 2022',
    warrantyExpiry: 'April 2025',
    lastService: 'April 2024',
    nextService: 'April 2025',
    serviceInterval: 'Annually',
    condition: 'excellent',
    assignedVendor: {
      name: "Mike's Plumbing",
      phone: '(203) 555-PIPE',
    },
  },
  {
    id: 'plumb-3',
    name: 'Septic System',
    category: 'plumbing',
    type: '1500 Gallon Concrete Tank',
    installDate: '1998 (Original)',
    lastService: 'May 2024',
    nextService: 'May 2027',
    serviceInterval: 'Every 3 years',
    condition: 'good',
    assignedVendor: {
      name: 'Greenwich Septic Services',
      phone: '(203) 555-SEPT',
      lastUsed: 'May 2024',
    },
  },
  // Electrical
  {
    id: 'elec-1',
    name: 'Main Electrical Panel',
    category: 'electrical',
    type: '400 Amp Main Panel',
    brand: 'Square D',
    installDate: '2018',
    condition: 'excellent',
    assignedVendor: {
      name: 'Tesla Certified Electricians',
      phone: '(203) 555-VOLT',
    },
    notes: 'Upgraded for EV charging capability',
  },
  {
    id: 'elec-2',
    name: 'EV Charger',
    category: 'electrical',
    type: 'Level 2 EV Charger',
    brand: 'Tesla',
    model: 'Wall Connector',
    installDate: 'January 2023',
    warrantyExpiry: 'January 2027',
    condition: 'excellent',
    assignedVendor: {
      name: 'Tesla Certified Electricians',
      phone: '(203) 555-VOLT',
    },
  },
  {
    id: 'elec-3',
    name: 'Whole Home Generator',
    category: 'electrical',
    type: 'Standby Generator',
    brand: 'Generac',
    model: 'Guardian 22kW',
    installDate: 'Pending Installation',
    condition: 'unknown',
    notes: 'Awaiting homeowner approval',
  },
  // Appliances
  {
    id: 'appl-1',
    name: 'Refrigerator',
    category: 'appliance',
    type: 'French Door Refrigerator',
    brand: 'Sub-Zero',
    model: 'BI-42SID',
    installDate: 'June 2019',
    warrantyExpiry: 'June 2024',
    condition: 'good',
    serviceInterval: 'Annual coil cleaning',
    lastService: 'June 2024',
    nextService: 'June 2025',
  },
  {
    id: 'appl-2',
    name: 'Range/Oven',
    category: 'appliance',
    type: 'Dual Fuel Range',
    brand: 'Wolf',
    model: 'DF486G',
    installDate: 'June 2019',
    warrantyExpiry: 'June 2021',
    condition: 'good',
  },
  {
    id: 'appl-3',
    name: 'Dishwasher',
    category: 'appliance',
    type: 'Built-in Dishwasher',
    brand: 'Miele',
    model: 'G7366',
    installDate: 'June 2019',
    warrantyExpiry: 'June 2021',
    condition: 'good',
  },
  {
    id: 'appl-4',
    name: 'Washer',
    category: 'appliance',
    type: 'Front Load Washer',
    brand: 'LG',
    model: 'WM9000HVA',
    installDate: 'March 2022',
    warrantyExpiry: 'March 2024',
    condition: 'excellent',
  },
  {
    id: 'appl-5',
    name: 'Dryer',
    category: 'appliance',
    type: 'Electric Dryer',
    brand: 'LG',
    model: 'DLEX9000V',
    installDate: 'March 2022',
    warrantyExpiry: 'March 2024',
    condition: 'excellent',
    lastService: 'October 2024',
    nextService: 'October 2025',
    serviceInterval: 'Annual vent cleaning',
    assignedVendor: {
      name: 'Dryer Vent Wizard',
      phone: '(203) 555-VENT',
    },
  },
  // Exterior
  {
    id: 'ext-1',
    name: 'Roof',
    category: 'exterior',
    type: 'Architectural Asphalt Shingles',
    brand: 'GAF',
    model: 'Timberline HDZ',
    installDate: 'September 2020',
    warrantyExpiry: 'September 2045',
    condition: 'excellent',
    lastService: 'September 2024',
    nextService: 'September 2025',
    serviceInterval: 'Annual inspection',
    assignedVendor: {
      name: 'Greenwich Roofing Co',
      phone: '(203) 555-ROOF',
    },
  },
  {
    id: 'ext-2',
    name: 'Gutters & Downspouts',
    category: 'exterior',
    type: 'Seamless Aluminum with Leaf Guards',
    installDate: 'September 2020',
    condition: 'excellent',
    lastService: 'November 2024',
    nextService: 'May 2025',
    serviceInterval: 'Twice yearly',
    assignedVendor: {
      name: 'Greenwich Roofing Co',
      phone: '(203) 555-ROOF',
    },
  },
  {
    id: 'ext-3',
    name: 'Exterior Paint',
    category: 'exterior',
    type: 'Benjamin Moore Exterior',
    installDate: 'May 2022',
    condition: 'good',
    notes: 'Color: Revere Pewter HC-172',
  },
  {
    id: 'ext-4',
    name: 'Driveway',
    category: 'exterior',
    type: 'Belgian Block Border with Asphalt',
    installDate: 'April 2021',
    condition: 'excellent',
    lastService: 'April 2024',
    nextService: 'April 2027',
    serviceInterval: 'Seal every 3 years',
  },
  // Security
  {
    id: 'sec-1',
    name: 'Security System',
    category: 'security',
    type: 'Monitored Alarm System',
    brand: 'ADT',
    installDate: 'June 2019',
    condition: 'good',
    assignedVendor: {
      name: 'ADT Security',
      phone: '(800) 555-4ADT',
    },
    notes: 'Monthly monitoring: $45',
  },
  {
    id: 'sec-2',
    name: 'Security Cameras',
    category: 'security',
    type: 'PoE Camera System',
    brand: 'Ubiquiti',
    model: 'UniFi Protect',
    installDate: 'August 2023',
    condition: 'excellent',
    notes: '8 cameras, NVR in basement',
  },
  {
    id: 'sec-3',
    name: 'Smart Locks',
    category: 'security',
    type: 'Smart Deadbolt',
    brand: 'Yale',
    model: 'Assure Lock 2',
    installDate: 'January 2024',
    condition: 'excellent',
    notes: 'Front and garage entry doors',
  },
  // Pool
  {
    id: 'pool-1',
    name: 'Pool',
    category: 'pool',
    type: 'In-Ground Gunite Pool',
    installDate: '1998 (Original)',
    condition: 'good',
    serviceInterval: 'Weekly during season',
    assignedVendor: {
      name: 'Pool Paradise CT',
      phone: '(203) 555-POOL',
    },
    notes: '20x40 ft, 3.5-8ft depth, heated',
  },
  {
    id: 'pool-2',
    name: 'Pool Heater',
    category: 'pool',
    type: 'Gas Pool Heater',
    brand: 'Hayward',
    model: 'H400FDN',
    installDate: 'May 2021',
    warrantyExpiry: 'May 2026',
    condition: 'excellent',
    assignedVendor: {
      name: 'Pool Paradise CT',
      phone: '(203) 555-POOL',
    },
  },
  {
    id: 'pool-3',
    name: 'Pool Pump & Filter',
    category: 'pool',
    type: 'Variable Speed Pump + DE Filter',
    brand: 'Pentair',
    model: 'IntelliFlo VSF',
    installDate: 'May 2021',
    warrantyExpiry: 'May 2024',
    condition: 'excellent',
    assignedVendor: {
      name: 'Pool Paradise CT',
      phone: '(203) 555-POOL',
    },
  },
];

const INSURANCE: InsuranceInfo = {
  provider: 'Chubb',
  policyNumber: 'HO-8847291-CT',
  premium: 8500,
  premiumFrequency: 'Annual',
  deductible: 5000,
  coverage: 3000000,
  expiryDate: 'June 15, 2025',
  agentName: 'David Chen',
  agentPhone: '(203) 555-CHUBB',
};

const IMPORTANT_CODES: ImportantCode[] = [
  { label: 'WiFi Network', value: 'Morrison_5G' },
  { label: 'WiFi Password', value: 'Greenwich2024!', hidden: true },
  { label: 'Alarm Code', value: '****', hidden: true },
  { label: 'Garage Code', value: '****', hidden: true },
  { label: 'Gate Code', value: '1234#' },
  { label: 'Pool Shed Lock', value: '0831' },
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

const getCategoryIcon = (category: string) => {
  switch (category) {
    case 'hvac': return ThermometerSun;
    case 'plumbing': return Droplets;
    case 'electrical': return Zap;
    case 'appliance': return Refrigerator;
    case 'exterior': return Home;
    case 'security': return Shield;
    case 'pool': return Waves;
    default: return Wrench;
  }
};

const getCategoryColor = (category: string) => {
  switch (category) {
    case 'hvac': return 'bg-orange-100 text-orange-600';
    case 'plumbing': return 'bg-blue-100 text-blue-600';
    case 'electrical': return 'bg-yellow-100 text-yellow-600';
    case 'appliance': return 'bg-purple-100 text-purple-600';
    case 'exterior': return 'bg-green-100 text-green-600';
    case 'security': return 'bg-red-100 text-red-600';
    case 'pool': return 'bg-cyan-100 text-cyan-600';
    default: return 'bg-warm-100 text-warm-600';
  }
};

const getConditionBadge = (condition: string) => {
  switch (condition) {
    case 'excellent': return { bg: 'bg-green-100', text: 'text-green-700', label: 'Excellent' };
    case 'good': return { bg: 'bg-blue-100', text: 'text-blue-700', label: 'Good' };
    case 'fair': return { bg: 'bg-amber-100', text: 'text-amber-700', label: 'Fair' };
    case 'needs-attention': return { bg: 'bg-red-100', text: 'text-red-700', label: 'Needs Attention' };
    default: return { bg: 'bg-warm-100', text: 'text-warm-600', label: 'Unknown' };
  }
};

const categories = [
  { id: 'hvac', label: 'HVAC & Climate', icon: ThermometerSun },
  { id: 'plumbing', label: 'Plumbing', icon: Droplets },
  { id: 'electrical', label: 'Electrical', icon: Zap },
  { id: 'appliance', label: 'Appliances', icon: Refrigerator },
  { id: 'exterior', label: 'Exterior', icon: Home },
  { id: 'security', label: 'Security', icon: Shield },
  { id: 'pool', label: 'Pool & Spa', icon: Waves },
];

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function YourHomePage() {
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(
    new Set(['hvac', 'plumbing'])
  );
  const [showCodes, setShowCodes] = useState(false);
  const [selectedSystem, setSelectedSystem] = useState<HomeSystem | null>(null);

  const toggleCategory = (categoryId: string) => {
    setExpandedCategories((prev) => {
      const next = new Set(prev);
      if (next.has(categoryId)) {
        next.delete(categoryId);
      } else {
        next.add(categoryId);
      }
      return next;
    });
  };

  const needsAttentionCount = HOME_SYSTEMS.filter(s => s.condition === 'needs-attention').length;
  const upcomingServiceCount = HOME_SYSTEMS.filter(s => {
    if (!s.nextService) return false;
    return s.nextService.includes('January') || s.nextService.includes('2025');
  }).length;

  return (
    <div className="min-h-screen bg-warm-50 pb-24 lg:pb-8">
      {/* HERO - Property Overview */}
      <div className="relative h-64 sm:h-80 overflow-hidden">
        <img
          src={PROPERTY.photoUrl}
          alt={PROPERTY.address}
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/40 to-transparent" />

        {/* Property Info Overlay */}
        <div className="absolute bottom-0 left-0 right-0 p-4 sm:p-6">
          <div className="max-w-6xl mx-auto">
            <div className="flex items-end justify-between gap-4">
              <div>
                <h1 className="text-2xl sm:text-3xl font-bold text-white">{PROPERTY.address}</h1>
                <p className="text-white/80 mt-1">
                  {PROPERTY.city}, {PROPERTY.state} {PROPERTY.zip}
                </p>
                <div className="flex flex-wrap items-center gap-3 mt-3">
                  <span className="flex items-center gap-1.5 text-white/90 text-sm">
                    <Bed className="w-4 h-4" />
                    {PROPERTY.bedrooms} bed
                  </span>
                  <span className="flex items-center gap-1.5 text-white/90 text-sm">
                    <Bath className="w-4 h-4" />
                    {PROPERTY.bathrooms} bath
                  </span>
                  <span className="flex items-center gap-1.5 text-white/90 text-sm">
                    <Square className="w-4 h-4" />
                    {PROPERTY.sqft.toLocaleString()} sqft
                  </span>
                  <span className="flex items-center gap-1.5 text-white/90 text-sm">
                    <TreePine className="w-4 h-4" />
                    {PROPERTY.lotSize}
                  </span>
                </div>
              </div>
              <button className="hidden sm:flex items-center gap-2 px-4 py-2 bg-white/20 backdrop-blur text-white rounded-xl hover:bg-white/30 transition-colors">
                <Edit className="w-4 h-4" />
                Edit
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* QUICK STATS */}
      <div className="max-w-6xl mx-auto px-4 -mt-6 relative z-10">
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div className="bg-white rounded-xl p-4 shadow-sm border border-warm-200">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-haven-100 flex items-center justify-center">
                <Wrench className="w-5 h-5 text-haven-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-warm-900">{HOME_SYSTEMS.length}</p>
                <p className="text-xs text-warm-500">Systems Tracked</p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl p-4 shadow-sm border border-warm-200">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center">
                <Clock className="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-warm-900">{upcomingServiceCount}</p>
                <p className="text-xs text-warm-500">Services Due</p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl p-4 shadow-sm border border-warm-200">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center">
                <CheckCircle2 className="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-warm-900">{HOME_SYSTEMS.filter(s => s.condition === 'excellent' || s.condition === 'good').length}</p>
                <p className="text-xs text-warm-500">Good Condition</p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl p-4 shadow-sm border border-warm-200">
            <div className="flex items-center gap-3">
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${needsAttentionCount > 0 ? 'bg-red-100' : 'bg-green-100'}`}>
                <AlertCircle className={`w-5 h-5 ${needsAttentionCount > 0 ? 'text-red-600' : 'text-green-600'}`} />
              </div>
              <div>
                <p className="text-2xl font-bold text-warm-900">{needsAttentionCount}</p>
                <p className="text-xs text-warm-500">Need Attention</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* MAIN CONTENT */}
      <div className="max-w-6xl mx-auto px-4 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

          {/* LEFT/MAIN - Systems Inventory */}
          <div className="lg:col-span-2 space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-warm-900">Home Systems</h2>
              <button className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-haven-600 hover:bg-haven-50 rounded-lg transition-colors">
                <Plus className="w-4 h-4" />
                Add System
              </button>
            </div>

            {/* Systems by Category */}
            {categories.map((category) => {
              const systems = HOME_SYSTEMS.filter(s => s.category === category.id);
              if (systems.length === 0) return null;

              const CategoryIcon = category.icon;
              const isExpanded = expandedCategories.has(category.id);

              return (
                <div key={category.id} className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
                  {/* Category Header */}
                  <button
                    onClick={() => toggleCategory(category.id)}
                    className="w-full p-4 flex items-center justify-between hover:bg-warm-50 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${getCategoryColor(category.id)}`}>
                        <CategoryIcon className="w-5 h-5" />
                      </div>
                      <div className="text-left">
                        <h3 className="font-semibold text-warm-900">{category.label}</h3>
                        <p className="text-sm text-warm-500">{systems.length} item{systems.length !== 1 ? 's' : ''}</p>
                      </div>
                    </div>
                    {isExpanded ? (
                      <ChevronDown className="w-5 h-5 text-warm-400" />
                    ) : (
                      <ChevronRight className="w-5 h-5 text-warm-400" />
                    )}
                  </button>

                  {/* Systems List */}
                  {isExpanded && (
                    <div className="border-t border-warm-100 divide-y divide-warm-100">
                      {systems.map((system) => {
                        const condition = getConditionBadge(system.condition);
                        return (
                          <div
                            key={system.id}
                            className="p-4 hover:bg-warm-50 transition-colors cursor-pointer"
                            onClick={() => setSelectedSystem(system)}
                          >
                            <div className="flex items-start justify-between gap-3">
                              <div className="flex-1 min-w-0">
                                <div className="flex items-center gap-2 flex-wrap">
                                  <h4 className="font-medium text-warm-900">{system.name}</h4>
                                  <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${condition.bg} ${condition.text}`}>
                                    {condition.label}
                                  </span>
                                </div>
                                <p className="text-sm text-warm-600 mt-0.5">{system.type}</p>
                                {system.brand && (
                                  <p className="text-xs text-warm-500 mt-1">
                                    {system.brand} {system.model}
                                  </p>
                                )}

                                {/* Service Info */}
                                <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-2 text-xs text-warm-500">
                                  {system.lastService && (
                                    <span className="flex items-center gap-1">
                                      <History className="w-3 h-3" />
                                      Last: {system.lastService}
                                    </span>
                                  )}
                                  {system.nextService && (
                                    <span className="flex items-center gap-1 text-haven-600 font-medium">
                                      <Calendar className="w-3 h-3" />
                                      Next: {system.nextService}
                                    </span>
                                  )}
                                  {system.warrantyExpiry && (
                                    <span className="flex items-center gap-1">
                                      <Shield className="w-3 h-3" />
                                      Warranty: {system.warrantyExpiry}
                                    </span>
                                  )}
                                </div>

                                {/* Assigned Vendor */}
                                {system.assignedVendor && (
                                  <div className="flex items-center gap-2 mt-2 p-2 bg-warm-50 rounded-lg">
                                    <VendorAvatar name={system.assignedVendor.name} size="sm" />
                                    <div className="flex-1 min-w-0">
                                      <p className="text-xs font-medium text-warm-700 truncate">{system.assignedVendor.name}</p>
                                      <p className="text-xs text-warm-500">{system.assignedVendor.phone}</p>
                                    </div>
                                    <a href={`tel:${system.assignedVendor.phone}`} className="p-1 text-haven-600 hover:bg-haven-100 rounded">
                                      <Phone className="w-4 h-4" />
                                    </a>
                                  </div>
                                )}
                              </div>
                              <ChevronRight className="w-5 h-5 text-warm-300 flex-shrink-0" />
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* RIGHT SIDEBAR */}
          <div className="space-y-6">

            {/* Property Details */}
            <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
              <div className="p-4 border-b border-warm-100">
                <h3 className="font-semibold text-warm-900">Property Details</h3>
              </div>
              <div className="p-4 space-y-3">
                <div className="flex justify-between text-sm">
                  <span className="text-warm-500">Type</span>
                  <span className="font-medium text-warm-900">{PROPERTY.propertyType}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-warm-500">Year Built</span>
                  <span className="font-medium text-warm-900">{PROPERTY.yearBuilt}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-warm-500">Stories</span>
                  <span className="font-medium text-warm-900">{PROPERTY.stories}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-warm-500">Garage</span>
                  <span className="font-medium text-warm-900">{PROPERTY.garage}</span>
                </div>
                {PROPERTY.purchaseDate && (
                  <>
                    <div className="h-px bg-warm-100 my-2" />
                    <div className="flex justify-between text-sm">
                      <span className="text-warm-500">Purchased</span>
                      <span className="font-medium text-warm-900">{PROPERTY.purchaseDate}</span>
                    </div>
                  </>
                )}
                {PROPERTY.currentValue && (
                  <div className="flex justify-between text-sm">
                    <span className="text-warm-500">Est. Value</span>
                    <span className="font-medium text-green-600">${(PROPERTY.currentValue / 1000000).toFixed(2)}M</span>
                  </div>
                )}
              </div>
            </div>

            {/* Insurance */}
            <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
              <div className="p-4 border-b border-warm-100 flex items-center justify-between">
                <h3 className="font-semibold text-warm-900">Insurance</h3>
                <button className="text-xs text-haven-600 font-medium">Edit</button>
              </div>
              <div className="p-4 space-y-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center">
                    <Shield className="w-5 h-5 text-blue-600" />
                  </div>
                  <div>
                    <p className="font-medium text-warm-900">{INSURANCE.provider}</p>
                    <p className="text-xs text-warm-500">Policy: {INSURANCE.policyNumber}</p>
                  </div>
                </div>
                <div className="h-px bg-warm-100" />
                <div className="grid grid-cols-2 gap-3 text-sm">
                  <div>
                    <p className="text-warm-500">Coverage</p>
                    <p className="font-medium text-warm-900">${(INSURANCE.coverage / 1000000).toFixed(1)}M</p>
                  </div>
                  <div>
                    <p className="text-warm-500">Deductible</p>
                    <p className="font-medium text-warm-900">${INSURANCE.deductible.toLocaleString()}</p>
                  </div>
                  <div>
                    <p className="text-warm-500">Premium</p>
                    <p className="font-medium text-warm-900">${INSURANCE.premium.toLocaleString()}/yr</p>
                  </div>
                  <div>
                    <p className="text-warm-500">Renews</p>
                    <p className="font-medium text-warm-900">{INSURANCE.expiryDate}</p>
                  </div>
                </div>
                {INSURANCE.agentName && (
                  <>
                    <div className="h-px bg-warm-100" />
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-medium text-warm-900">{INSURANCE.agentName}</p>
                        <p className="text-xs text-warm-500">Your Agent</p>
                      </div>
                      <a href={`tel:${INSURANCE.agentPhone}`} className="p-2 text-haven-600 hover:bg-haven-50 rounded-lg">
                        <Phone className="w-4 h-4" />
                      </a>
                    </div>
                  </>
                )}
              </div>
            </div>

            {/* Important Codes */}
            <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
              <div className="p-4 border-b border-warm-100 flex items-center justify-between">
                <h3 className="font-semibold text-warm-900">Quick Reference</h3>
                <button
                  onClick={() => setShowCodes(!showCodes)}
                  className="text-xs text-haven-600 font-medium"
                >
                  {showCodes ? 'Hide' : 'Show'}
                </button>
              </div>
              <div className="p-4 space-y-2">
                {IMPORTANT_CODES.map((code, idx) => (
                  <div key={idx} className="flex justify-between text-sm">
                    <span className="text-warm-500">{code.label}</span>
                    <span className="font-mono font-medium text-warm-900">
                      {code.hidden && !showCodes ? '••••••••' : code.value}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Documents */}
            <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
              <div className="p-4 border-b border-warm-100 flex items-center justify-between">
                <h3 className="font-semibold text-warm-900">Documents</h3>
                <button className="flex items-center gap-1 text-xs text-haven-600 font-medium">
                  <Upload className="w-3 h-3" />
                  Upload
                </button>
              </div>
              <div className="p-4 space-y-2">
                {[
                  { name: 'Homeowners Insurance Policy', type: 'pdf' },
                  { name: 'Property Deed', type: 'pdf' },
                  { name: 'Survey & Plot Plan', type: 'pdf' },
                  { name: 'Roof Warranty Certificate', type: 'pdf' },
                  { name: 'HVAC Service Contract', type: 'pdf' },
                ].map((doc, idx) => (
                  <a
                    key={idx}
                    href="#"
                    className="flex items-center gap-3 p-2 hover:bg-warm-50 rounded-lg transition-colors"
                  >
                    <FileText className="w-5 h-5 text-warm-400" />
                    <span className="text-sm text-warm-700 flex-1 truncate">{doc.name}</span>
                    <ExternalLink className="w-4 h-4 text-warm-300" />
                  </a>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* SYSTEM DETAIL MODAL */}
      {selectedSystem && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-end sm:items-center justify-center p-0 sm:p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setSelectedSystem(null)} />
            <div className="relative bg-white w-full sm:max-w-lg sm:rounded-2xl overflow-hidden max-h-[90vh] overflow-y-auto rounded-t-2xl">
              {/* Header */}
              <div className="sticky top-0 bg-white border-b border-warm-200 p-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${getCategoryColor(selectedSystem.category)}`}>
                    {(() => { const Icon = getCategoryIcon(selectedSystem.category); return <Icon className="w-5 h-5" />; })()}
                  </div>
                  <div>
                    <h3 className="font-semibold text-warm-900">{selectedSystem.name}</h3>
                    <p className="text-sm text-warm-500">{selectedSystem.type}</p>
                  </div>
                </div>
                <button
                  onClick={() => setSelectedSystem(null)}
                  className="p-2 hover:bg-warm-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-warm-400" />
                </button>
              </div>

              {/* Content */}
              <div className="p-4 space-y-4">
                {/* Condition */}
                <div className="flex items-center justify-between p-3 bg-warm-50 rounded-xl">
                  <span className="text-sm text-warm-600">Condition</span>
                  {(() => {
                    const c = getConditionBadge(selectedSystem.condition);
                    return <span className={`px-3 py-1 text-sm font-medium rounded-full ${c.bg} ${c.text}`}>{c.label}</span>;
                  })()}
                </div>

                {/* Details Grid */}
                <div className="grid grid-cols-2 gap-3">
                  {selectedSystem.brand && (
                    <div className="p-3 bg-warm-50 rounded-xl">
                      <p className="text-xs text-warm-500">Brand</p>
                      <p className="font-medium text-warm-900">{selectedSystem.brand}</p>
                    </div>
                  )}
                  {selectedSystem.model && (
                    <div className="p-3 bg-warm-50 rounded-xl">
                      <p className="text-xs text-warm-500">Model</p>
                      <p className="font-medium text-warm-900">{selectedSystem.model}</p>
                    </div>
                  )}
                  {selectedSystem.installDate && (
                    <div className="p-3 bg-warm-50 rounded-xl">
                      <p className="text-xs text-warm-500">Installed</p>
                      <p className="font-medium text-warm-900">{selectedSystem.installDate}</p>
                    </div>
                  )}
                  {selectedSystem.warrantyExpiry && (
                    <div className="p-3 bg-warm-50 rounded-xl">
                      <p className="text-xs text-warm-500">Warranty Until</p>
                      <p className="font-medium text-warm-900">{selectedSystem.warrantyExpiry}</p>
                    </div>
                  )}
                </div>

                {/* Service Schedule */}
                {(selectedSystem.lastService || selectedSystem.nextService) && (
                  <div>
                    <h4 className="text-sm font-medium text-warm-700 mb-2">Service Schedule</h4>
                    <div className="space-y-2">
                      {selectedSystem.serviceInterval && (
                        <div className="flex justify-between text-sm p-3 bg-warm-50 rounded-xl">
                          <span className="text-warm-600">Interval</span>
                          <span className="font-medium text-warm-900">{selectedSystem.serviceInterval}</span>
                        </div>
                      )}
                      {selectedSystem.lastService && (
                        <div className="flex justify-between text-sm p-3 bg-warm-50 rounded-xl">
                          <span className="text-warm-600">Last Service</span>
                          <span className="font-medium text-warm-900">{selectedSystem.lastService}</span>
                        </div>
                      )}
                      {selectedSystem.nextService && (
                        <div className="flex justify-between text-sm p-3 bg-haven-50 rounded-xl">
                          <span className="text-haven-700">Next Service</span>
                          <span className="font-medium text-haven-700">{selectedSystem.nextService}</span>
                        </div>
                      )}
                    </div>
                  </div>
                )}

                {/* Assigned Vendor */}
                {selectedSystem.assignedVendor && (
                  <div>
                    <h4 className="text-sm font-medium text-warm-700 mb-2">Assigned Vendor</h4>
                    <div className="flex items-center gap-3 p-3 bg-warm-50 rounded-xl">
                      <VendorAvatar name={selectedSystem.assignedVendor.name} size="lg" />
                      <div className="flex-1">
                        <p className="font-medium text-warm-900">{selectedSystem.assignedVendor.name}</p>
                        <p className="text-sm text-warm-500">{selectedSystem.assignedVendor.phone}</p>
                        {selectedSystem.assignedVendor.lastUsed && (
                          <p className="text-xs text-warm-400 mt-0.5">Last used: {selectedSystem.assignedVendor.lastUsed}</p>
                        )}
                      </div>
                      <div className="flex gap-2">
                        <a href={`tel:${selectedSystem.assignedVendor.phone}`} className="p-2 bg-haven-100 text-haven-600 rounded-lg">
                          <Phone className="w-4 h-4" />
                        </a>
                      </div>
                    </div>
                  </div>
                )}

                {/* Notes */}
                {selectedSystem.notes && (
                  <div>
                    <h4 className="text-sm font-medium text-warm-700 mb-2">Notes</h4>
                    <p className="text-sm text-warm-600 p-3 bg-warm-50 rounded-xl">{selectedSystem.notes}</p>
                  </div>
                )}
              </div>

              {/* Footer Actions */}
              <div className="sticky bottom-0 bg-white border-t border-warm-200 p-4 flex gap-3">
                <button className="flex-1 py-2.5 border border-warm-200 text-warm-700 font-medium rounded-xl hover:bg-warm-50 transition-colors">
                  Edit System
                </button>
                <button className="flex-1 py-2.5 bg-haven-600 text-white font-medium rounded-xl hover:bg-haven-700 transition-colors">
                  Schedule Service
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
