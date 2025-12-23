# Haven: Home Profile Page + Essentials Tier + Pricing Update

## Overview

This prompt covers:
1. **Your Home page** - Comprehensive home profile showing all systems, maintenance, vendors
2. **Essentials Tier Dashboard** - Simplified navigation for $39/month subscribers
3. **Website Pricing Update** - Essentials prominent, dropdowns for Haven+/Estate

---

# PART 1: YOUR HOME PAGE (All Tiers)

## File: `apps/web/src/app/app/home/page.tsx`

This is the comprehensive home profile - the "database" of everything about the property.

```tsx
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
    new Set(['hvac', 'plumbing']) // Start with some expanded
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

  // Count systems needing attention
  const needsAttentionCount = HOME_SYSTEMS.filter(s => s.condition === 'needs-attention').length;
  const upcomingServiceCount = HOME_SYSTEMS.filter(s => {
    if (!s.nextService) return false;
    // Simplified check - in real app would parse dates
    return s.nextService.includes('January') || s.nextService.includes('2025');
  }).length;

  return (
    <div className="min-h-screen bg-warm-50 pb-24 lg:pb-8">
      {/* ================================================================== */}
      {/* HERO - Property Overview */}
      {/* ================================================================== */}
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

      {/* ================================================================== */}
      {/* QUICK STATS */}
      {/* ================================================================== */}
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

      {/* ================================================================== */}
      {/* MAIN CONTENT */}
      {/* ================================================================== */}
      <div className="max-w-6xl mx-auto px-4 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          {/* ============================================================ */}
          {/* LEFT/MAIN - Systems Inventory */}
          {/* ============================================================ */}
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
                                    <button className="p-1 text-haven-600 hover:bg-haven-100 rounded">
                                      <Phone className="w-4 h-4" />
                                    </button>
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

          {/* ============================================================ */}
          {/* RIGHT SIDEBAR */}
          {/* ============================================================ */}
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

      {/* ================================================================== */}
      {/* SYSTEM DETAIL MODAL */}
      {/* ================================================================== */}
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
```

---

# PART 2: NAVIGATION UPDATES

## Update Desktop Sidebar

**File:** `apps/web/src/components/app-shell/desktop-sidebar.tsx`

Add "Your Home" to the navigation and update the structure:

```tsx
// Navigation structure based on subscription tier
const getNavigation = (tier: 'essentials' | 'plus' | 'estate') => {
  const baseNav = [
    { name: 'Dashboard', href: '/app', icon: LayoutDashboard },
    { name: 'Your Home', href: '/app/home', icon: Home }, // NEW - All tiers
  ];

  if (tier === 'essentials') {
    return [
      ...baseNav,
      { name: 'Money', href: '/app/money', icon: DollarSign },
      { name: 'Maintenance', href: '/app/maintenance', icon: Wrench },
      { name: 'Find Pros', href: '/app/community', icon: Search },
      { name: 'Messages', href: '/app/messages', icon: MessageCircle },
    ];
  }

  // Haven+ and Estate get the Manager hub
  return [
    ...baseNav,
    { 
      name: 'Sarah', // Dynamic manager name
      href: '/app/manager', 
      icon: User,
      badge: pendingRequestsCount,
      highlight: true,
    },
    { name: 'Messages', href: '/app/messages', icon: MessageCircle },
    { type: 'divider', label: 'Your Home' },
    { name: 'Family', href: '/app/family', icon: Users },
    { name: 'Projects', href: '/app/projects', icon: Hammer },
    { name: 'Maintenance', href: '/app/maintenance', icon: Wrench },
    { name: 'Find Pros', href: '/app/community', icon: Search },
    { type: 'divider', label: 'Financial' },
    { name: 'Money', href: '/app/money', icon: DollarSign },
    { name: 'Documents', href: '/app/documents', icon: FileText },
  ];
};
```

## Update Mobile Nav for Essentials

**For Essentials tier:**
```
Home | Your Home | Money | Vendors | More
```

**For Haven+ / Estate:**
```
Home | Sarah | Messages | Money | More
```

---

# PART 3: WEBSITE PRICING PAGE UPDATE

## File: `apps/web/src/app/(marketing)/pricing/page.tsx` or in the main marketing page

```tsx
'use client';

import { useState } from 'react';
import {
  Check,
  ChevronDown,
  ChevronUp,
  Home,
  DollarSign,
  Wrench,
  Users,
  MessageCircle,
  Calendar,
  FileText,
  Shield,
  Star,
  Clock,
  Phone,
  Sparkles,
  Crown,
  Building,
} from 'lucide-react';

export default function PricingSection() {
  const [expandedTier, setExpandedTier] = useState<'plus' | 'estate' | null>(null);

  return (
    <section className="py-16 sm:py-24 bg-white">
      <div className="max-w-5xl mx-auto px-4 sm:px-6">
        {/* Header */}
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
            Simple, Transparent Pricing
          </h2>
          <p className="text-lg text-warm-600 mt-4 max-w-2xl mx-auto">
            Start with bill consolidation, upgrade when you're ready for a dedicated home manager.
          </p>
        </div>

        {/* Pricing Cards */}
        <div className="space-y-4">
          
          {/* ============================================================ */}
          {/* ESSENTIALS - Primary/Prominent */}
          {/* ============================================================ */}
          <div className="bg-white rounded-2xl border-2 border-haven-500 shadow-lg overflow-hidden">
            <div className="p-6 sm:p-8">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="text-2xl font-bold text-warm-900">Haven Essentials</h3>
                    <span className="px-2 py-0.5 bg-haven-100 text-haven-700 text-xs font-medium rounded-full">
                      Most Popular
                    </span>
                  </div>
                  <p className="text-warm-600 mt-1">
                    Bill consolidation & home tracking — manage it yourself
                  </p>
                </div>
                <div className="text-left sm:text-right">
                  <div className="flex items-baseline gap-1">
                    <span className="text-4xl font-bold text-warm-900">$39</span>
                    <span className="text-warm-500">/month</span>
                  </div>
                  <p className="text-sm text-warm-500">No setup fee</p>
                </div>
              </div>

              {/* Features Grid */}
              <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-3">
                {[
                  { icon: DollarSign, text: 'Bill consolidation — one monthly payment' },
                  { icon: Home, text: 'Complete home systems inventory' },
                  { icon: Clock, text: 'Maintenance reminders & scheduling' },
                  { icon: Users, text: 'Vendor directory with neighbor reviews' },
                  { icon: FileText, text: 'Document storage & warranties' },
                  { icon: Wrench, text: 'Pay-per-use handyman visits ($99/visit)' },
                ].map((feature, idx) => (
                  <div key={idx} className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-haven-100 flex items-center justify-center flex-shrink-0">
                      <feature.icon className="w-4 h-4 text-haven-600" />
                    </div>
                    <span className="text-sm text-warm-700">{feature.text}</span>
                  </div>
                ))}
              </div>

              {/* CTA */}
              <div className="mt-6 flex flex-col sm:flex-row gap-3">
                <button className="flex-1 py-3 bg-haven-600 text-white font-semibold rounded-xl hover:bg-haven-700 transition-colors">
                  Get Started — It's Free to Try
                </button>
                <button className="py-3 px-6 border border-warm-200 text-warm-700 font-medium rounded-xl hover:bg-warm-50 transition-colors">
                  Learn More
                </button>
              </div>
            </div>
          </div>

          {/* ============================================================ */}
          {/* HAVEN+ - Expandable */}
          {/* ============================================================ */}
          <div className="bg-warm-50 rounded-2xl border border-warm-200 overflow-hidden">
            <button
              onClick={() => setExpandedTier(expandedTier === 'plus' ? null : 'plus')}
              className="w-full p-6 flex items-center justify-between hover:bg-warm-100 transition-colors"
            >
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-purple-100 flex items-center justify-center">
                  <Star className="w-6 h-6 text-purple-600" />
                </div>
                <div className="text-left">
                  <h3 className="text-xl font-bold text-warm-900">Haven+</h3>
                  <p className="text-warm-600 text-sm">Part-time home manager included</p>
                </div>
              </div>
              <div className="flex items-center gap-4">
                <div className="text-right">
                  <div className="flex items-baseline gap-1">
                    <span className="text-2xl font-bold text-warm-900">$349</span>
                    <span className="text-warm-500 text-sm">/month</span>
                  </div>
                </div>
                {expandedTier === 'plus' ? (
                  <ChevronUp className="w-5 h-5 text-warm-400" />
                ) : (
                  <ChevronDown className="w-5 h-5 text-warm-400" />
                )}
              </div>
            </button>

            {expandedTier === 'plus' && (
              <div className="px-6 pb-6 border-t border-warm-200">
                <div className="pt-6">
                  <p className="text-warm-600 mb-4">
                    Everything in Essentials, plus a dedicated home manager who handles vendor coordination, 
                    scheduling, and proactive maintenance — so you don't have to.
                  </p>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {[
                      'Dedicated Home Manager (~10 hrs/month)',
                      'Proactive vendor coordination',
                      'Bill payment & tracking',
                      'Maintenance scheduling & oversight',
                      'Monthly handyman visit included',
                      'Project coordination',
                      'Priority support',
                      'Family portal access',
                    ].map((feature, idx) => (
                      <div key={idx} className="flex items-center gap-2">
                        <Check className="w-4 h-4 text-purple-600 flex-shrink-0" />
                        <span className="text-sm text-warm-700">{feature}</span>
                      </div>
                    ))}
                  </div>
                  <button className="mt-6 w-full py-3 bg-purple-600 text-white font-semibold rounded-xl hover:bg-purple-700 transition-colors">
                    Upgrade to Haven+
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* ============================================================ */}
          {/* HAVEN ESTATE - Expandable */}
          {/* ============================================================ */}
          <div className="bg-warm-50 rounded-2xl border border-warm-200 overflow-hidden">
            <button
              onClick={() => setExpandedTier(expandedTier === 'estate' ? null : 'estate')}
              className="w-full p-6 flex items-center justify-between hover:bg-warm-100 transition-colors"
            >
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center">
                  <Crown className="w-6 h-6 text-amber-600" />
                </div>
                <div className="text-left">
                  <h3 className="text-xl font-bold text-warm-900">Haven Estate</h3>
                  <p className="text-warm-600 text-sm">Full-time manager for complex households</p>
                </div>
              </div>
              <div className="flex items-center gap-4">
                <div className="text-right">
                  <div className="flex items-baseline gap-1">
                    <span className="text-2xl font-bold text-warm-900">$749</span>
                    <span className="text-warm-500 text-sm">/month</span>
                  </div>
                </div>
                {expandedTier === 'estate' ? (
                  <ChevronUp className="w-5 h-5 text-warm-400" />
                ) : (
                  <ChevronDown className="w-5 h-5 text-warm-400" />
                )}
              </div>
            </button>

            {expandedTier === 'estate' && (
              <div className="px-6 pb-6 border-t border-warm-200">
                <div className="pt-6">
                  <p className="text-warm-600 mb-4">
                    White-glove service for estates and high-net-worth households. Unlimited support, 
                    multi-property management, and concierge-level attention to detail.
                  </p>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {[
                      'Dedicated full-time Home Manager',
                      'Unlimited vendor coordination',
                      'Multi-property support',
                      'Weekly property inspections',
                      'Unlimited handyman visits',
                      'Major project management',
                      'Concierge services',
                      'Travel & seasonal home prep',
                      '24/7 emergency response',
                      'Staff management assistance',
                    ].map((feature, idx) => (
                      <div key={idx} className="flex items-center gap-2">
                        <Check className="w-4 h-4 text-amber-600 flex-shrink-0" />
                        <span className="text-sm text-warm-700">{feature}</span>
                      </div>
                    ))}
                  </div>
                  <button className="mt-6 w-full py-3 bg-amber-600 text-white font-semibold rounded-xl hover:bg-amber-700 transition-colors">
                    Contact Sales
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Trust Elements */}
        <div className="mt-12 text-center">
          <p className="text-warm-500 text-sm">
            No long-term contracts • Cancel anytime • 30-day money-back guarantee
          </p>
        </div>
      </div>
    </section>
  );
}
```

---

# PART 4: UPDATE COMPARISON TABLE

Also update the comparison table on the marketing page to compare Essentials vs Haven+ vs traditional software:

```tsx
{/* Mobile Comparison - Stacked Cards */}
<div className="lg:hidden space-y-3">
  {[
    { feature: 'Monthly Cost', essentials: '$39', plus: '$349', them: '$375+' },
    { feature: 'Setup Fee', essentials: '$0', plus: '$0', them: '$3K-$5K' },
    { feature: 'Bill Consolidation', essentials: '✓', plus: '✓', them: 'No' },
    { feature: 'Maintenance Reminders', essentials: '✓', plus: '✓', them: '✓' },
    { feature: 'Home Manager', essentials: 'Self-service', plus: 'Dedicated person', them: 'No', highlight: true },
    { feature: 'Vendor Coordination', essentials: 'DIY', plus: 'We handle it', them: 'No', highlight: true },
    { feature: 'Handyman Visits', essentials: '$99/visit', plus: 'Included', them: 'No' },
  ].map((row, idx) => (
    <div key={idx} className={`bg-white rounded-xl border overflow-hidden ${row.highlight ? 'border-haven-300' : 'border-warm-200'}`}>
      <div className="bg-warm-100 px-4 py-2">
        <span className="font-medium text-warm-700 text-sm">{row.feature}</span>
      </div>
      <div className="grid grid-cols-3 divide-x divide-warm-100">
        <div className="p-3 text-center">
          <div className="text-xs text-warm-400 mb-1">Essentials</div>
          <div className="text-sm font-medium text-haven-700">{row.essentials}</div>
        </div>
        <div className="p-3 text-center bg-haven-50/50">
          <div className="text-xs text-haven-600 mb-1">Haven+</div>
          <div className="text-sm font-medium text-haven-700">{row.plus}</div>
        </div>
        <div className="p-3 text-center">
          <div className="text-xs text-warm-400 mb-1">Others</div>
          <div className="text-sm text-warm-500">{row.them}</div>
        </div>
      </div>
    </div>
  ))}
</div>
```

---

# SUMMARY

## Files to Create/Update:

1. **`apps/web/src/app/app/home/page.tsx`** - "Your Home" page with complete home profile
   - Property overview with hero image
   - All home systems organized by category
   - Maintenance schedules and assigned vendors
   - Insurance info, documents, important codes

2. **Navigation updates** - Add "Your Home" to all tier navigations
   - Desktop sidebar
   - Mobile nav

3. **Marketing pricing page** - Essentials prominent, expandable Haven+/Estate

## Navigation by Tier:

**Essentials ($39/mo):**
```
Dashboard | Your Home | Money | Maintenance | Vendors | Messages
```

**Haven+ ($349/mo):**
```
Dashboard | Your Home | Sarah | Messages | Money | More
```

---

## Run in Claude Code:

```
Read and apply HAVEN_HOME_PROFILE.md

This creates:
1. "Your Home" page - comprehensive home profile with all systems, vendors, maintenance schedules
2. Update navigation to include "Your Home" for all tiers
3. Update marketing pricing page - Essentials prominent ($39), expandable dropdowns for Haven+ ($349) and Estate ($749)

Key features of Your Home page:
- Hero image of the property
- Quick stats (systems tracked, services due, condition)
- Systems inventory organized by category (HVAC, Plumbing, Electrical, etc.)
- Each system shows: brand, model, install date, warranty, service schedule, assigned vendor
- Insurance info with agent contact
- Important codes (WiFi, alarm, gate)
- Document storage

Use the Greenwich house image and all existing mock data (Bob Morrison, vendors like Mike's Plumbing, Comfort Zone HVAC, etc.)
```
