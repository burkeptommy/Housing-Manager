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
  Shield,
  Car,
  Waves,
  TreePine,
  Refrigerator,
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
  Users,
  DollarSign,
  Settings,
  Landmark,
  TrendingUp,
  X,
} from 'lucide-react';
import { VendorAvatar } from '@/components/ui/avatar';

// ============================================================================
// TYPES
// ============================================================================

type TabId = 'overview' | 'systems' | 'vendors' | 'vehicles' | 'financial' | 'documents';

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
  zillowUrl?: string;
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
    id: string;
    name: string;
    phone: string;
  };
  notes?: string;
}

interface Vendor {
  id: string;
  name: string;
  category: string;
  phone: string;
  email?: string;
  website?: string;
  address?: string;
  rating: number;
  reviewCount: number;
  lastUsed?: string;
  totalSpent?: number;
  notes?: string;
  isPreferred: boolean;
  servicesProvided: string[];
}

interface Vehicle {
  id: string;
  name: string;
  year: number;
  make: string;
  model: string;
  color: string;
  vin?: string;
  licensePlate: string;
  mileage: number;
  insuranceProvider?: string;
  insurancePolicy?: string;
  registrationExpiry: string;
  nextService?: string;
  photoUrl?: string;
}

interface Loan {
  id: string;
  type: 'mortgage' | 'heloc' | 'auto' | 'other';
  lender: string;
  accountNumber: string;
  originalAmount: number;
  currentBalance: number;
  interestRate: number;
  monthlyPayment: number;
  paymentDueDay: number;
  maturityDate: string;
  propertyAddress?: string;
  vehicleId?: string;
}

interface Document {
  id: string;
  name: string;
  category: string;
  uploadDate: string;
  fileType: string;
  fileSize: string;
  url: string;
}

// ============================================================================
// MOCK DATA - PROPERTY (Using actual 38 Bedford Rd Greenwich listing)
// ============================================================================

const PROPERTY: PropertyInfo = {
  address: '38 Bedford Road',
  city: 'Greenwich',
  state: 'CT',
  zip: '06831',
  propertyType: 'Single Family',
  yearBuilt: 1954,
  sqft: 5765,
  lotSize: '2.0 acres',
  bedrooms: 5,
  bathrooms: 5.5,
  garage: '2-car attached',
  stories: 2,
  // Use the actual Zillow listing photo
  photoUrl: 'https://photos.zillowstatic.com/fp/c2a65e47b1e40de4e3dbf3ee2763b256-cc_ft_1536.webp',
  purchaseDate: 'June 2019',
  purchasePrice: 2495000,
  currentValue: 3150000,
  zillowUrl: 'https://www.zillow.com/homedetails/38-Bedford-Rd-Greenwich-CT-06831/240524148_zpid/',
};

// ============================================================================
// MOCK DATA - HOME SYSTEMS
// ============================================================================

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
    assignedVendor: { id: 'v-1', name: 'Comfort Zone HVAC', phone: '(203) 555-2665' },
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
    assignedVendor: { id: 'v-1', name: 'Comfort Zone HVAC', phone: '(203) 555-2665' },
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
    assignedVendor: { id: 'v-2', name: "Mike's Plumbing", phone: '(203) 555-7473' },
  },
  // Plumbing
  {
    id: 'plumb-1',
    name: 'Well Pump System',
    category: 'plumbing',
    type: 'Submersible Well Pump',
    brand: 'Goulds',
    installDate: '2018',
    condition: 'good',
    assignedVendor: { id: 'v-2', name: "Mike's Plumbing", phone: '(203) 555-7473' },
    notes: 'Private well, 400ft depth',
  },
  {
    id: 'plumb-2',
    name: 'Septic System',
    category: 'plumbing',
    type: '1500 Gallon Concrete Tank',
    installDate: '2010 (Replaced)',
    lastService: 'May 2024',
    nextService: 'May 2027',
    serviceInterval: 'Every 3 years',
    condition: 'good',
    assignedVendor: { id: 'v-6', name: 'Greenwich Septic Services', phone: '(203) 555-7378' },
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
    assignedVendor: { id: 'v-3', name: 'Tesla Certified Electricians', phone: '(203) 555-8658' },
    notes: 'Upgraded for EV charging capability',
  },
  {
    id: 'elec-2',
    name: 'EV Charger',
    category: 'electrical',
    type: 'Level 2 EV Charger',
    brand: 'Tesla',
    model: 'Wall Connector Gen 3',
    installDate: 'January 2023',
    warrantyExpiry: 'January 2027',
    condition: 'excellent',
    assignedVendor: { id: 'v-3', name: 'Tesla Certified Electricians', phone: '(203) 555-8658' },
  },
  {
    id: 'elec-3',
    name: 'Whole Home Generator',
    category: 'electrical',
    type: 'Standby Generator',
    brand: 'Generac',
    model: 'Guardian 24kW',
    installDate: 'November 2021',
    warrantyExpiry: 'November 2026',
    lastService: 'November 2024',
    nextService: 'May 2025',
    serviceInterval: 'Every 6 months',
    condition: 'excellent',
    assignedVendor: { id: 'v-3', name: 'Tesla Certified Electricians', phone: '(203) 555-8658' },
  },
  // Appliances
  {
    id: 'appl-1',
    name: 'Refrigerator',
    category: 'appliance',
    type: 'French Door Refrigerator',
    brand: 'Sub-Zero',
    model: 'BI-48SID',
    installDate: 'June 2019',
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
    condition: 'excellent',
  },
  {
    id: 'appl-3',
    name: 'Dishwasher',
    category: 'appliance',
    type: 'Built-in Dishwasher',
    brand: 'Miele',
    model: 'G7566',
    installDate: 'March 2023',
    warrantyExpiry: 'March 2026',
    condition: 'excellent',
  },
  // Exterior
  {
    id: 'ext-1',
    name: 'Roof',
    category: 'exterior',
    type: 'Slate Roof',
    installDate: '1954 (Original, restored 2015)',
    condition: 'good',
    lastService: 'September 2024',
    nextService: 'September 2025',
    serviceInterval: 'Annual inspection',
    assignedVendor: { id: 'v-8', name: 'Greenwich Roofing Co', phone: '(203) 555-7663' },
    notes: 'Original slate, some tiles replaced 2015',
  },
  {
    id: 'ext-2',
    name: 'Gutters & Downspouts',
    category: 'exterior',
    type: 'Copper Gutters with Leaf Guards',
    installDate: '2015',
    condition: 'excellent',
    lastService: 'November 2024',
    nextService: 'May 2025',
    serviceInterval: 'Twice yearly',
    assignedVendor: { id: 'v-8', name: 'Greenwich Roofing Co', phone: '(203) 555-7663' },
  },
  // Security
  {
    id: 'sec-1',
    name: 'Security System',
    category: 'security',
    type: 'Monitored Alarm System',
    brand: 'Alarm.com',
    installDate: 'June 2019',
    condition: 'good',
    assignedVendor: { id: 'v-9', name: 'SecureHome CT', phone: '(203) 555-7328' },
    notes: 'Monthly monitoring: $45',
  },
  {
    id: 'sec-2',
    name: 'Security Cameras',
    category: 'security',
    type: 'PoE Camera System',
    brand: 'Verkada',
    installDate: 'August 2023',
    condition: 'excellent',
    notes: '12 cameras, cloud storage',
  },
  // Pool
  {
    id: 'pool-1',
    name: 'Swimming Pool',
    category: 'pool',
    type: 'In-Ground Gunite Pool',
    installDate: '1985 (Renovated 2018)',
    condition: 'excellent',
    serviceInterval: 'Weekly during season',
    assignedVendor: { id: 'v-4', name: 'Pool Paradise CT', phone: '(203) 555-7665' },
    notes: '20x45 ft, 3.5-9ft depth, heated, saltwater',
  },
  {
    id: 'pool-2',
    name: 'Pool Heater',
    category: 'pool',
    type: 'Heat Pump Pool Heater',
    brand: 'Hayward',
    model: 'HeatPro HP21404T',
    installDate: 'May 2021',
    warrantyExpiry: 'May 2026',
    condition: 'excellent',
    assignedVendor: { id: 'v-4', name: 'Pool Paradise CT', phone: '(203) 555-7665' },
  },
];

// ============================================================================
// MOCK DATA - VENDORS
// ============================================================================

const VENDORS: Vendor[] = [
  {
    id: 'v-1',
    name: 'Comfort Zone HVAC',
    category: 'HVAC',
    phone: '(203) 555-2665',
    email: 'service@comfortzonehvac.com',
    website: 'www.comfortzonehvac.com',
    address: '45 Industrial Park Rd, Greenwich, CT',
    rating: 4.9,
    reviewCount: 127,
    lastUsed: 'October 2024',
    totalSpent: 3450,
    isPreferred: true,
    servicesProvided: ['HVAC Maintenance', 'AC Repair', 'Furnace Service', 'Air Quality'],
    notes: 'Ask for Mike - he knows our system well',
  },
  {
    id: 'v-2',
    name: "Mike's Plumbing",
    category: 'Plumbing',
    phone: '(203) 555-7473',
    email: 'mike@mikesplumbing.com',
    rating: 4.8,
    reviewCount: 89,
    lastUsed: 'December 2024',
    totalSpent: 2890,
    isPreferred: true,
    servicesProvided: ['Plumbing Repair', 'Water Heater', 'Well Pump', 'Water Treatment'],
  },
  {
    id: 'v-3',
    name: 'Tesla Certified Electricians',
    category: 'Electrical',
    phone: '(203) 555-8658',
    email: 'info@teslacertified.com',
    website: 'www.teslacertifiedct.com',
    rating: 4.9,
    reviewCount: 156,
    lastUsed: 'November 2024',
    totalSpent: 18500,
    isPreferred: true,
    servicesProvided: ['EV Charger Install', 'Generator Service', 'Electrical Panel', 'Smart Home'],
  },
  {
    id: 'v-4',
    name: 'Pool Paradise CT',
    category: 'Pool Service',
    phone: '(203) 555-7665',
    email: 'service@poolparadisect.com',
    rating: 4.7,
    reviewCount: 203,
    lastUsed: 'October 2024',
    totalSpent: 4200,
    isPreferred: true,
    servicesProvided: ['Weekly Pool Service', 'Opening/Closing', 'Equipment Repair', 'Renovation'],
    notes: 'Season contract: $350/month May-September',
  },
  {
    id: 'v-5',
    name: 'Greenwich Landscaping',
    category: 'Landscaping',
    phone: '(203) 555-5263',
    email: 'info@greenwichlandscaping.com',
    website: 'www.greenwichlandscaping.com',
    rating: 4.6,
    reviewCount: 312,
    lastUsed: 'November 2024',
    totalSpent: 12800,
    isPreferred: true,
    servicesProvided: ['Lawn Care', 'Landscape Design', 'Tree Service', 'Snow Removal'],
    notes: 'Annual contract: $1,800/month',
  },
  {
    id: 'v-6',
    name: 'Greenwich Septic Services',
    category: 'Septic',
    phone: '(203) 555-7378',
    rating: 4.5,
    reviewCount: 67,
    lastUsed: 'May 2024',
    totalSpent: 850,
    isPreferred: false,
    servicesProvided: ['Septic Pumping', 'Inspection', 'Repair'],
  },
  {
    id: 'v-8',
    name: 'Greenwich Roofing Co',
    category: 'Roofing',
    phone: '(203) 555-7663',
    email: 'info@greenwichroofing.com',
    rating: 4.7,
    reviewCount: 145,
    lastUsed: 'November 2024',
    totalSpent: 2400,
    isPreferred: true,
    servicesProvided: ['Roof Inspection', 'Slate Repair', 'Gutter Service'],
  },
  {
    id: 'v-9',
    name: 'SecureHome CT',
    category: 'Security',
    phone: '(203) 555-7328',
    rating: 4.6,
    reviewCount: 78,
    lastUsed: 'June 2024',
    totalSpent: 1200,
    isPreferred: false,
    servicesProvided: ['Alarm Monitoring', 'Camera Install', 'Smart Lock Install'],
  },
];

// ============================================================================
// MOCK DATA - VEHICLES
// ============================================================================

const VEHICLES: Vehicle[] = [
  {
    id: 'veh-1',
    name: "Bob's Tesla",
    year: 2023,
    make: 'Tesla',
    model: 'Model Y Long Range',
    color: 'Pearl White',
    vin: '5YJ3E1EA8PF123456',
    licensePlate: 'CT-TESLA1',
    mileage: 24500,
    insuranceProvider: 'Chubb',
    insurancePolicy: 'AUTO-887429',
    registrationExpiry: 'March 2025',
    nextService: 'January 2025',
    photoUrl: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=400&h=300&fit=crop',
  },
  {
    id: 'veh-2',
    name: 'Family Highlander',
    year: 2022,
    make: 'Toyota',
    model: 'Highlander Hybrid Platinum',
    color: 'Celestial Silver',
    vin: '5TDZBRCH7NS123456',
    licensePlate: 'CT-FAM2022',
    mileage: 35200,
    insuranceProvider: 'Chubb',
    insurancePolicy: 'AUTO-887430',
    registrationExpiry: 'June 2025',
    nextService: 'February 2025',
    photoUrl: 'https://images.unsplash.com/photo-1619682817481-e994891cd1f5?w=400&h=300&fit=crop',
  },
  {
    id: 'veh-3',
    name: "Alice's Mercedes",
    year: 2024,
    make: 'Mercedes-Benz',
    model: 'GLE 450 4MATIC',
    color: 'Obsidian Black',
    vin: '4JGFB4KB7RA123456',
    licensePlate: 'CT-AMB2024',
    mileage: 8750,
    insuranceProvider: 'Chubb',
    insurancePolicy: 'AUTO-887431',
    registrationExpiry: 'September 2025',
    nextService: 'September 2025',
    photoUrl: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=400&h=300&fit=crop',
  },
];

// ============================================================================
// MOCK DATA - LOANS & MORTGAGES
// ============================================================================

const LOANS: Loan[] = [
  {
    id: 'loan-1',
    type: 'mortgage',
    lender: 'First Republic Bank',
    accountNumber: '****7891',
    originalAmount: 1750000,
    currentBalance: 1425000,
    interestRate: 3.125,
    monthlyPayment: 7498,
    paymentDueDay: 1,
    maturityDate: 'June 2049',
    propertyAddress: '38 Bedford Road, Greenwich, CT',
  },
  {
    id: 'loan-2',
    type: 'heloc',
    lender: 'First Republic Bank',
    accountNumber: '****7892',
    originalAmount: 500000,
    currentBalance: 125000,
    interestRate: 7.25,
    monthlyPayment: 0,
    paymentDueDay: 15,
    maturityDate: 'June 2034',
    propertyAddress: '38 Bedford Road, Greenwich, CT',
  },
  {
    id: 'loan-3',
    type: 'auto',
    lender: 'Tesla Financing',
    accountNumber: '****4521',
    originalAmount: 65000,
    currentBalance: 42000,
    interestRate: 4.99,
    monthlyPayment: 1150,
    paymentDueDay: 15,
    maturityDate: 'January 2028',
    vehicleId: 'veh-1',
  },
];

// ============================================================================
// MOCK DATA - DOCUMENTS
// ============================================================================

const DOCUMENTS: Document[] = [
  { id: 'doc-1', name: 'Homeowners Insurance Policy', category: 'Insurance', uploadDate: 'Jun 2024', fileType: 'pdf', fileSize: '2.4 MB', url: '#' },
  { id: 'doc-2', name: 'Property Deed', category: 'Property', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '1.1 MB', url: '#' },
  { id: 'doc-3', name: 'Survey & Plot Plan', category: 'Property', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '4.2 MB', url: '#' },
  { id: 'doc-4', name: 'Mortgage Documents', category: 'Financial', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '3.8 MB', url: '#' },
  { id: 'doc-5', name: 'HVAC Warranty Certificate', category: 'Warranties', uploadDate: 'Mar 2021', fileType: 'pdf', fileSize: '856 KB', url: '#' },
  { id: 'doc-6', name: 'Roof Inspection Report', category: 'Maintenance', uploadDate: 'Sep 2024', fileType: 'pdf', fileSize: '1.2 MB', url: '#' },
  { id: 'doc-7', name: 'Pool Renovation Plans', category: 'Projects', uploadDate: 'Apr 2018', fileType: 'pdf', fileSize: '5.6 MB', url: '#' },
  { id: 'doc-8', name: 'Generator Install Manual', category: 'Manuals', uploadDate: 'Nov 2021', fileType: 'pdf', fileSize: '2.1 MB', url: '#' },
  { id: 'doc-9', name: 'Auto Insurance Policy', category: 'Insurance', uploadDate: 'Sep 2024', fileType: 'pdf', fileSize: '1.8 MB', url: '#' },
  { id: 'doc-10', name: 'Well Water Test Results', category: 'Maintenance', uploadDate: 'Aug 2024', fileType: 'pdf', fileSize: '456 KB', url: '#' },
];

// ============================================================================
// MOCK DATA - INSURANCE
// ============================================================================

const INSURANCE = {
  home: {
    provider: 'Chubb',
    policyNumber: 'HO-8847291-CT',
    premium: 12500,
    premiumFrequency: 'Annual',
    deductible: 10000,
    coverage: 4500000,
    expiryDate: 'June 15, 2025',
    agentName: 'David Chen',
    agentPhone: '(203) 555-2482',
  },
  auto: {
    provider: 'Chubb',
    policyNumber: 'AUTO-887429',
    premium: 4800,
    premiumFrequency: 'Annual',
    vehicles: 3,
    expiryDate: 'September 1, 2025',
  },
  umbrella: {
    provider: 'Chubb',
    policyNumber: 'UMB-112847',
    premium: 1500,
    coverage: 5000000,
    expiryDate: 'June 15, 2025',
  },
};

// ============================================================================
// MOCK DATA - IMPORTANT CODES
// ============================================================================

const IMPORTANT_CODES = [
  { label: 'WiFi Network', value: 'Morrison_5G' },
  { label: 'WiFi Password', value: 'Greenwich2024!', hidden: true },
  { label: 'Alarm Code', value: '****', hidden: true },
  { label: 'Gate Code', value: '1234#' },
  { label: 'Garage Keypad', value: '****', hidden: true },
  { label: 'Pool Shed Lock', value: '0831' },
  { label: 'Generator Override', value: '****', hidden: true },
];

// ============================================================================
// TABS CONFIGURATION
// ============================================================================

const TABS: { id: TabId; label: string; icon: typeof Home }[] = [
  { id: 'overview', label: 'Overview', icon: Home },
  { id: 'systems', label: 'Systems', icon: Wrench },
  { id: 'vendors', label: 'Vendors', icon: Users },
  { id: 'vehicles', label: 'Vehicles', icon: Car },
  { id: 'financial', label: 'Financial', icon: DollarSign },
  { id: 'documents', label: 'Documents', icon: FileText },
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

const systemCategories = [
  { id: 'hvac', label: 'HVAC & Climate', icon: ThermometerSun },
  { id: 'plumbing', label: 'Plumbing & Water', icon: Droplets },
  { id: 'electrical', label: 'Electrical', icon: Zap },
  { id: 'appliance', label: 'Appliances', icon: Refrigerator },
  { id: 'exterior', label: 'Exterior', icon: TreePine },
  { id: 'security', label: 'Security', icon: Shield },
  { id: 'pool', label: 'Pool & Spa', icon: Waves },
];

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function YourHomePage() {
  const [activeTab, setActiveTab] = useState<TabId>('overview');
  const [expandedCategory, setExpandedCategory] = useState<string | null>('hvac');
  const [showCodes, setShowCodes] = useState(false);
  const [selectedSystem, setSelectedSystem] = useState<HomeSystem | null>(null);

  // Stats
  const systemsCount = HOME_SYSTEMS.length;
  const vendorsCount = VENDORS.length;
  const upcomingServiceCount = HOME_SYSTEMS.filter(s => s.nextService).length;
  const needsAttentionCount = HOME_SYSTEMS.filter(s => s.condition === 'needs-attention').length;

  // ============================================================================
  // RENDER OVERVIEW TAB
  // ============================================================================
  const renderOverview = () => (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Left Column - Property Details */}
      <div className="lg:col-span-2 space-y-6">
        {/* Property Card */}
        <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
          <div className="relative h-64 sm:h-80">
            <img
              src={PROPERTY.photoUrl}
              alt={PROPERTY.address}
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-transparent" />
            <div className="absolute bottom-0 left-0 right-0 p-6">
              <h2 className="text-2xl font-bold text-white">{PROPERTY.address}</h2>
              <p className="text-white/80">{PROPERTY.city}, {PROPERTY.state} {PROPERTY.zip}</p>
              <div className="flex flex-wrap items-center gap-4 mt-3">
                <span className="flex items-center gap-1.5 text-white/90 text-sm">
                  <Bed className="w-4 h-4" /> {PROPERTY.bedrooms} bed
                </span>
                <span className="flex items-center gap-1.5 text-white/90 text-sm">
                  <Bath className="w-4 h-4" /> {PROPERTY.bathrooms} bath
                </span>
                <span className="flex items-center gap-1.5 text-white/90 text-sm">
                  <Square className="w-4 h-4" /> {PROPERTY.sqft.toLocaleString()} sqft
                </span>
                <span className="flex items-center gap-1.5 text-white/90 text-sm">
                  <TreePine className="w-4 h-4" /> {PROPERTY.lotSize}
                </span>
              </div>
            </div>
            {PROPERTY.zillowUrl && (
              <a
                href={PROPERTY.zillowUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="absolute top-4 right-4 flex items-center gap-1 px-3 py-1.5 bg-white/90 text-warm-700 text-xs font-medium rounded-full hover:bg-white transition-colors"
              >
                <ExternalLink className="w-3 h-3" />
                View on Zillow
              </a>
            )}
          </div>

          {/* Property Stats */}
          <div className="p-6 grid grid-cols-2 sm:grid-cols-4 gap-4">
            <div>
              <p className="text-sm text-warm-500">Year Built</p>
              <p className="font-semibold text-warm-900">{PROPERTY.yearBuilt}</p>
            </div>
            <div>
              <p className="text-sm text-warm-500">Property Type</p>
              <p className="font-semibold text-warm-900">{PROPERTY.propertyType}</p>
            </div>
            <div>
              <p className="text-sm text-warm-500">Purchased</p>
              <p className="font-semibold text-warm-900">{PROPERTY.purchaseDate}</p>
            </div>
            <div>
              <p className="text-sm text-warm-500">Est. Value</p>
              <p className="font-semibold text-green-600">${(PROPERTY.currentValue! / 1000000).toFixed(2)}M</p>
            </div>
          </div>
        </div>

        {/* Quick Stats Cards */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div className="bg-white rounded-xl p-4 shadow-sm border border-warm-200">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-haven-100 flex items-center justify-center">
                <Wrench className="w-5 h-5 text-haven-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-warm-900">{systemsCount}</p>
                <p className="text-xs text-warm-500">Systems</p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl p-4 shadow-sm border border-warm-200">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center">
                <Users className="w-5 h-5 text-purple-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-warm-900">{vendorsCount}</p>
                <p className="text-xs text-warm-500">Vendors</p>
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

        {/* Upcoming Maintenance */}
        <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
          <div className="p-4 border-b border-warm-100 flex items-center justify-between">
            <h3 className="font-semibold text-warm-900">Upcoming Maintenance</h3>
            <button onClick={() => setActiveTab('systems')} className="text-sm text-haven-600 font-medium hover:text-haven-700">View All</button>
          </div>
          <div className="divide-y divide-warm-100">
            {HOME_SYSTEMS.filter(s => s.nextService).slice(0, 5).map(system => {
              const CategoryIcon = getCategoryIcon(system.category);
              return (
                <div key={system.id} className="p-4 flex items-center gap-4">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${getCategoryColor(system.category)}`}>
                    <CategoryIcon className="w-5 h-5" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-warm-900">{system.name}</p>
                    <p className="text-sm text-warm-500">{system.assignedVendor?.name || 'No vendor assigned'}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium text-haven-600">{system.nextService}</p>
                    <p className="text-xs text-warm-500">{system.serviceInterval}</p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Right Column */}
      <div className="space-y-6">
        {/* Insurance Summary */}
        <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
          <div className="p-4 border-b border-warm-100">
            <h3 className="font-semibold text-warm-900">Insurance</h3>
          </div>
          <div className="p-4 space-y-4">
            <div className="flex items-center gap-3 p-3 bg-warm-50 rounded-xl">
              <div className="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center">
                <Home className="w-5 h-5 text-blue-600" />
              </div>
              <div className="flex-1">
                <p className="font-medium text-warm-900">Home - {INSURANCE.home.provider}</p>
                <p className="text-xs text-warm-500">${(INSURANCE.home.coverage / 1000000).toFixed(1)}M coverage</p>
              </div>
            </div>
            <div className="flex items-center gap-3 p-3 bg-warm-50 rounded-xl">
              <div className="w-10 h-10 rounded-lg bg-green-100 flex items-center justify-center">
                <Car className="w-5 h-5 text-green-600" />
              </div>
              <div className="flex-1">
                <p className="font-medium text-warm-900">Auto - {INSURANCE.auto.provider}</p>
                <p className="text-xs text-warm-500">{INSURANCE.auto.vehicles} vehicles</p>
              </div>
            </div>
            <div className="flex items-center gap-3 p-3 bg-warm-50 rounded-xl">
              <div className="w-10 h-10 rounded-lg bg-purple-100 flex items-center justify-center">
                <Shield className="w-5 h-5 text-purple-600" />
              </div>
              <div className="flex-1">
                <p className="font-medium text-warm-900">Umbrella - {INSURANCE.umbrella.provider}</p>
                <p className="text-xs text-warm-500">${(INSURANCE.umbrella.coverage / 1000000)}M coverage</p>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Reference */}
        <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
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

        {/* Preferred Vendors */}
        <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
          <div className="p-4 border-b border-warm-100 flex items-center justify-between">
            <h3 className="font-semibold text-warm-900">Preferred Vendors</h3>
            <button onClick={() => setActiveTab('vendors')} className="text-sm text-haven-600 font-medium hover:text-haven-700">View All</button>
          </div>
          <div className="divide-y divide-warm-100">
            {VENDORS.filter(v => v.isPreferred).slice(0, 4).map(vendor => (
              <div key={vendor.id} className="p-3 flex items-center gap-3">
                <VendorAvatar name={vendor.name} size="md" />
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-warm-900 text-sm truncate">{vendor.name}</p>
                  <p className="text-xs text-warm-500">{vendor.category}</p>
                </div>
                <a href={`tel:${vendor.phone}`} className="p-2 text-haven-600 hover:bg-haven-50 rounded-lg">
                  <Phone className="w-4 h-4" />
                </a>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  // ============================================================================
  // RENDER SYSTEMS TAB
  // ============================================================================
  const renderSystems = () => (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-warm-900">Home Systems</h2>
        <button className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-haven-600 hover:bg-haven-50 rounded-lg">
          <Plus className="w-4 h-4" /> Add System
        </button>
      </div>

      {systemCategories.map(category => {
        const systems = HOME_SYSTEMS.filter(s => s.category === category.id);
        if (systems.length === 0) return null;

        const isExpanded = expandedCategory === category.id;
        const CategoryIcon = category.icon;

        return (
          <div key={category.id} className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
            <button
              onClick={() => setExpandedCategory(isExpanded ? null : category.id)}
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
              {isExpanded ? <ChevronDown className="w-5 h-5 text-warm-400" /> : <ChevronRight className="w-5 h-5 text-warm-400" />}
            </button>

            {isExpanded && (
              <div className="border-t border-warm-100 divide-y divide-warm-100">
                {systems.map(system => {
                  const condition = getConditionBadge(system.condition);
                  return (
                    <div
                      key={system.id}
                      className="p-4 hover:bg-warm-50 cursor-pointer transition-colors"
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
                          {system.brand && <p className="text-xs text-warm-500 mt-1">{system.brand} {system.model}</p>}

                          <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-2 text-xs text-warm-500">
                            {system.lastService && <span>Last: {system.lastService}</span>}
                            {system.nextService && <span className="text-haven-600 font-medium">Next: {system.nextService}</span>}
                            {system.warrantyExpiry && <span>Warranty: {system.warrantyExpiry}</span>}
                          </div>

                          {system.assignedVendor && (
                            <div className="flex items-center gap-2 mt-2 p-2 bg-warm-50 rounded-lg">
                              <VendorAvatar name={system.assignedVendor.name} size="sm" />
                              <span className="text-xs text-warm-700">{system.assignedVendor.name}</span>
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

      {/* System Detail Modal */}
      {selectedSystem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50" onClick={() => setSelectedSystem(null)}>
          <div className="bg-white rounded-2xl max-w-lg w-full max-h-[90vh] overflow-y-auto" onClick={e => e.stopPropagation()}>
            <div className="p-6">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="text-xl font-bold text-warm-900">{selectedSystem.name}</h3>
                  <p className="text-warm-600">{selectedSystem.type}</p>
                </div>
                <button onClick={() => setSelectedSystem(null)} className="p-2 hover:bg-warm-100 rounded-lg">
                  <X className="w-5 h-5 text-warm-500" />
                </button>
              </div>
              <div className="space-y-4">
                {selectedSystem.brand && (
                  <div>
                    <p className="text-sm text-warm-500">Brand & Model</p>
                    <p className="font-medium text-warm-900">{selectedSystem.brand} {selectedSystem.model}</p>
                  </div>
                )}
                {selectedSystem.installDate && (
                  <div>
                    <p className="text-sm text-warm-500">Install Date</p>
                    <p className="font-medium text-warm-900">{selectedSystem.installDate}</p>
                  </div>
                )}
                {selectedSystem.warrantyExpiry && (
                  <div>
                    <p className="text-sm text-warm-500">Warranty Expires</p>
                    <p className="font-medium text-warm-900">{selectedSystem.warrantyExpiry}</p>
                  </div>
                )}
                {selectedSystem.assignedVendor && (
                  <div>
                    <p className="text-sm text-warm-500">Assigned Vendor</p>
                    <div className="flex items-center gap-3 mt-1">
                      <VendorAvatar name={selectedSystem.assignedVendor.name} size="md" />
                      <div>
                        <p className="font-medium text-warm-900">{selectedSystem.assignedVendor.name}</p>
                        <p className="text-sm text-warm-500">{selectedSystem.assignedVendor.phone}</p>
                      </div>
                    </div>
                  </div>
                )}
                {selectedSystem.notes && (
                  <div>
                    <p className="text-sm text-warm-500">Notes</p>
                    <p className="font-medium text-warm-900">{selectedSystem.notes}</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );

  // ============================================================================
  // RENDER VENDORS TAB
  // ============================================================================
  const renderVendors = () => (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-warm-900">Your Vendors</h2>
        <button className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-haven-600 hover:bg-haven-50 rounded-lg">
          <Plus className="w-4 h-4" /> Add Vendor
        </button>
      </div>

      {/* Preferred Vendors */}
      <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
        <div className="p-4 border-b border-warm-100">
          <h3 className="font-semibold text-warm-900 flex items-center gap-2">
            <Star className="w-4 h-4 text-amber-500 fill-current" />
            Preferred Vendors
          </h3>
        </div>
        <div className="divide-y divide-warm-100">
          {VENDORS.filter(v => v.isPreferred).map(vendor => (
            <div key={vendor.id} className="p-4 hover:bg-warm-50 transition-colors">
              <div className="flex items-start gap-4">
                <VendorAvatar name={vendor.name} size="lg" />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h4 className="font-medium text-warm-900">{vendor.name}</h4>
                    <span className="px-2 py-0.5 bg-warm-100 text-warm-600 text-xs rounded-full">{vendor.category}</span>
                  </div>
                  <div className="flex items-center gap-2 mt-1 text-sm">
                    <Star className="w-4 h-4 text-amber-500 fill-current" />
                    <span className="font-medium text-warm-900">{vendor.rating}</span>
                    <span className="text-warm-500">({vendor.reviewCount} reviews)</span>
                  </div>
                  <div className="flex flex-wrap gap-1 mt-2">
                    {vendor.servicesProvided.slice(0, 3).map(service => (
                      <span key={service} className="px-2 py-0.5 bg-haven-50 text-haven-700 text-xs rounded-full">{service}</span>
                    ))}
                  </div>
                </div>
                <div className="text-right flex-shrink-0">
                  <p className="text-sm font-medium text-warm-900">${vendor.totalSpent?.toLocaleString()}</p>
                  <p className="text-xs text-warm-500">Total spent</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Other Vendors */}
      <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
        <div className="p-4 border-b border-warm-100">
          <h3 className="font-semibold text-warm-900">Other Vendors</h3>
        </div>
        <div className="divide-y divide-warm-100">
          {VENDORS.filter(v => !v.isPreferred).map(vendor => (
            <div key={vendor.id} className="p-4 hover:bg-warm-50 transition-colors">
              <div className="flex items-center gap-4">
                <VendorAvatar name={vendor.name} size="md" />
                <div className="flex-1 min-w-0">
                  <h4 className="font-medium text-warm-900">{vendor.name}</h4>
                  <p className="text-sm text-warm-500">{vendor.category}</p>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Star className="w-4 h-4 text-amber-500 fill-current" />
                  <span>{vendor.rating}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  // ============================================================================
  // RENDER VEHICLES TAB
  // ============================================================================
  const renderVehicles = () => (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-warm-900">Your Vehicles</h2>
        <button className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-haven-600 hover:bg-haven-50 rounded-lg">
          <Plus className="w-4 h-4" /> Add Vehicle
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {VEHICLES.map(vehicle => (
          <div
            key={vehicle.id}
            className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden hover:shadow-md transition-shadow"
          >
            {vehicle.photoUrl && (
              <div className="h-40 overflow-hidden">
                <img src={vehicle.photoUrl} alt={vehicle.name} className="w-full h-full object-cover" />
              </div>
            )}
            <div className="p-4">
              <h3 className="font-semibold text-warm-900">{vehicle.name}</h3>
              <p className="text-sm text-warm-600">{vehicle.year} {vehicle.make} {vehicle.model}</p>
              <div className="mt-3 grid grid-cols-2 gap-2 text-xs">
                <div className="p-2 bg-warm-50 rounded-lg">
                  <p className="text-warm-500">Mileage</p>
                  <p className="font-medium text-warm-900">{vehicle.mileage.toLocaleString()} mi</p>
                </div>
                <div className="p-2 bg-warm-50 rounded-lg">
                  <p className="text-warm-500">Registration</p>
                  <p className="font-medium text-warm-900">{vehicle.registrationExpiry}</p>
                </div>
              </div>
              {vehicle.nextService && (
                <div className="mt-2 p-2 bg-haven-50 rounded-lg">
                  <p className="text-xs text-haven-700">
                    <span className="font-medium">Next Service:</span> {vehicle.nextService}
                  </p>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  // ============================================================================
  // RENDER FINANCIAL TAB
  // ============================================================================
  const renderFinancial = () => (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-warm-900">Financial Overview</h2>

      {/* Mortgage & Loans */}
      <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
        <div className="p-4 border-b border-warm-100">
          <h3 className="font-semibold text-warm-900 flex items-center gap-2">
            <Landmark className="w-5 h-5 text-warm-400" />
            Mortgages & Loans
          </h3>
        </div>
        <div className="divide-y divide-warm-100">
          {LOANS.map(loan => (
            <div key={loan.id} className="p-4">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <div className="flex items-center gap-2">
                    <h4 className="font-medium text-warm-900">
                      {loan.type === 'mortgage' ? 'Mortgage' :
                       loan.type === 'heloc' ? 'HELOC' :
                       loan.type === 'auto' ? 'Auto Loan' : 'Loan'}
                    </h4>
                    <span className="text-xs text-warm-500">{loan.accountNumber}</span>
                  </div>
                  <p className="text-sm text-warm-600">{loan.lender}</p>
                </div>
                <div className="text-right">
                  <p className="text-lg font-bold text-warm-900">${loan.currentBalance.toLocaleString()}</p>
                  <p className="text-xs text-warm-500">Balance</p>
                </div>
              </div>
              <div className="mt-3 grid grid-cols-4 gap-3 text-sm">
                <div>
                  <p className="text-warm-500 text-xs">Rate</p>
                  <p className="font-medium text-warm-900">{loan.interestRate}%</p>
                </div>
                <div>
                  <p className="text-warm-500 text-xs">Payment</p>
                  <p className="font-medium text-warm-900">${loan.monthlyPayment.toLocaleString()}/mo</p>
                </div>
                <div>
                  <p className="text-warm-500 text-xs">Due</p>
                  <p className="font-medium text-warm-900">{loan.paymentDueDay}th</p>
                </div>
                <div>
                  <p className="text-warm-500 text-xs">Matures</p>
                  <p className="font-medium text-warm-900">{loan.maturityDate}</p>
                </div>
              </div>
              {/* Progress Bar */}
              <div className="mt-3">
                <div className="flex justify-between text-xs text-warm-500 mb-1">
                  <span>Paid: ${(loan.originalAmount - loan.currentBalance).toLocaleString()}</span>
                  <span>Original: ${loan.originalAmount.toLocaleString()}</span>
                </div>
                <div className="h-2 bg-warm-100 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-haven-500 rounded-full"
                    style={{ width: `${((loan.originalAmount - loan.currentBalance) / loan.originalAmount) * 100}%` }}
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Insurance Policies */}
      <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
        <div className="p-4 border-b border-warm-100">
          <h3 className="font-semibold text-warm-900 flex items-center gap-2">
            <Shield className="w-5 h-5 text-warm-400" />
            Insurance Policies
          </h3>
        </div>
        <div className="divide-y divide-warm-100">
          <div className="p-4">
            <div className="flex items-start justify-between">
              <div>
                <h4 className="font-medium text-warm-900">Homeowners Insurance</h4>
                <p className="text-sm text-warm-600">{INSURANCE.home.provider} - {INSURANCE.home.policyNumber}</p>
              </div>
              <div className="text-right">
                <p className="font-bold text-warm-900">${INSURANCE.home.premium.toLocaleString()}/yr</p>
              </div>
            </div>
            <div className="mt-2 grid grid-cols-3 gap-3 text-sm">
              <div>
                <p className="text-warm-500 text-xs">Coverage</p>
                <p className="font-medium text-warm-900">${(INSURANCE.home.coverage / 1000000).toFixed(1)}M</p>
              </div>
              <div>
                <p className="text-warm-500 text-xs">Deductible</p>
                <p className="font-medium text-warm-900">${INSURANCE.home.deductible.toLocaleString()}</p>
              </div>
              <div>
                <p className="text-warm-500 text-xs">Renewal</p>
                <p className="font-medium text-warm-900">{INSURANCE.home.expiryDate}</p>
              </div>
            </div>
          </div>
          <div className="p-4">
            <div className="flex items-start justify-between">
              <div>
                <h4 className="font-medium text-warm-900">Auto Insurance</h4>
                <p className="text-sm text-warm-600">{INSURANCE.auto.provider} - {INSURANCE.auto.policyNumber}</p>
              </div>
              <div className="text-right">
                <p className="font-bold text-warm-900">${INSURANCE.auto.premium.toLocaleString()}/yr</p>
              </div>
            </div>
            <div className="mt-2 flex items-center gap-4 text-sm">
              <div>
                <p className="text-warm-500 text-xs">Vehicles</p>
                <p className="font-medium text-warm-900">{INSURANCE.auto.vehicles}</p>
              </div>
              <div>
                <p className="text-warm-500 text-xs">Renewal</p>
                <p className="font-medium text-warm-900">{INSURANCE.auto.expiryDate}</p>
              </div>
            </div>
          </div>
          <div className="p-4">
            <div className="flex items-start justify-between">
              <div>
                <h4 className="font-medium text-warm-900">Umbrella Policy</h4>
                <p className="text-sm text-warm-600">{INSURANCE.umbrella.provider} - {INSURANCE.umbrella.policyNumber}</p>
              </div>
              <div className="text-right">
                <p className="font-bold text-warm-900">${INSURANCE.umbrella.premium.toLocaleString()}/yr</p>
              </div>
            </div>
            <div className="mt-2 text-sm">
              <p className="text-warm-500 text-xs">Coverage</p>
              <p className="font-medium text-warm-900">${(INSURANCE.umbrella.coverage / 1000000)}M</p>
            </div>
          </div>
        </div>
      </div>

      {/* Property Value */}
      <div className="bg-gradient-to-br from-haven-600 to-haven-700 rounded-xl p-6 text-white">
        <h3 className="font-semibold flex items-center gap-2">
          <TrendingUp className="w-5 h-5" />
          Property Value
        </h3>
        <div className="mt-4 grid grid-cols-2 gap-4">
          <div>
            <p className="text-haven-200 text-sm">Purchase Price</p>
            <p className="text-2xl font-bold">${(PROPERTY.purchasePrice! / 1000000).toFixed(2)}M</p>
            <p className="text-haven-200 text-xs">{PROPERTY.purchaseDate}</p>
          </div>
          <div>
            <p className="text-haven-200 text-sm">Current Estimate</p>
            <p className="text-2xl font-bold">${(PROPERTY.currentValue! / 1000000).toFixed(2)}M</p>
            <p className="text-green-300 text-xs font-medium">
              +${((PROPERTY.currentValue! - PROPERTY.purchasePrice!) / 1000).toFixed(0)}K ({(((PROPERTY.currentValue! - PROPERTY.purchasePrice!) / PROPERTY.purchasePrice!) * 100).toFixed(1)}%)
            </p>
          </div>
        </div>
      </div>
    </div>
  );

  // ============================================================================
  // RENDER DOCUMENTS TAB
  // ============================================================================
  const renderDocuments = () => {
    const categories = [...new Set(DOCUMENTS.map(d => d.category))];

    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-warm-900">Documents</h2>
          <button className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-haven-600 hover:bg-haven-50 rounded-lg">
            <Upload className="w-4 h-4" /> Upload
          </button>
        </div>

        {categories.map(category => (
          <div key={category} className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
            <div className="p-4 border-b border-warm-100">
              <h3 className="font-semibold text-warm-900">{category}</h3>
            </div>
            <div className="divide-y divide-warm-100">
              {DOCUMENTS.filter(d => d.category === category).map(doc => (
                <a
                  key={doc.id}
                  href={doc.url}
                  className="p-4 flex items-center gap-4 hover:bg-warm-50 transition-colors"
                >
                  <div className="w-10 h-10 rounded-lg bg-red-100 flex items-center justify-center">
                    <FileText className="w-5 h-5 text-red-600" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-warm-900 truncate">{doc.name}</p>
                    <p className="text-xs text-warm-500">{doc.fileSize} • Uploaded {doc.uploadDate}</p>
                  </div>
                  <ExternalLink className="w-4 h-4 text-warm-400" />
                </a>
              ))}
            </div>
          </div>
        ))}
      </div>
    );
  };

  // ============================================================================
  // MAIN RENDER
  // ============================================================================
  return (
    <div className="min-h-screen bg-warm-50 pb-24 lg:pb-8">
      {/* Header */}
      <div className="bg-white border-b border-warm-200 sticky top-0 z-20">
        <div className="max-w-6xl mx-auto px-4">
          {/* Title */}
          <div className="py-4 flex items-center justify-between">
            <h1 className="text-xl font-bold text-warm-900">Your Home</h1>
            <button className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-warm-600 hover:bg-warm-50 rounded-lg">
              <Settings className="w-4 h-4" />
              Settings
            </button>
          </div>

          {/* Tabs */}
          <div className="flex gap-1 overflow-x-auto pb-px scrollbar-hide">
            {TABS.map(tab => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 px-4 py-3 text-sm font-medium whitespace-nowrap border-b-2 transition-colors ${
                    isActive
                      ? 'border-haven-600 text-haven-600'
                      : 'border-transparent text-warm-500 hover:text-warm-700'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-6xl mx-auto px-4 py-6">
        {activeTab === 'overview' && renderOverview()}
        {activeTab === 'systems' && renderSystems()}
        {activeTab === 'vendors' && renderVendors()}
        {activeTab === 'vehicles' && renderVehicles()}
        {activeTab === 'financial' && renderFinancial()}
        {activeTab === 'documents' && renderDocuments()}
      </div>
    </div>
  );
}
