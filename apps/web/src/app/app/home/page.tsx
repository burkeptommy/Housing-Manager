'use client';

import { useState, useMemo } from 'react';
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
  ChevronUp,
  AlertCircle,
  AlertTriangle,
  CheckCircle2,
  Clock,
  Star,
  Phone,
  Mail,
  ExternalLink,
  Edit,
  MoreHorizontal,
  Pencil,
  Building,
  Key,
  Users,
  DollarSign,
  CalendarDays,
  CalendarClock,
  History,
  Package,
  Settings,
  Info,
  CreditCard,
  Landmark,
  Receipt,
  TrendingUp,
  TrendingDown,
  X,
  Globe,
  Search,
  Filter,
  SortAsc,
  Bell,
  BellRing,
  Paperclip,
  MessageCircle,
  ArrowRight,
  ArrowUpRight,
  Timer,
  CircleDot,
  ListFilter,
  LayoutGrid,
  List,
  Eye,
  EyeOff,
  Download,
  Copy,
  MoreVertical,
  FolderOpen,
  FileImage,
  Gauge,
  CarFront,
  FileCheck,
  BadgeCheck,
  Banknote,
  RefreshCw,
  GraduationCap,
  PiggyBank,
  Percent,
  Heart,
} from 'lucide-react';
import { VendorAvatar } from '@/components/ui/avatar';

// ============================================================================
// TYPES
// ============================================================================

type TabId = 'overview' | 'maintenance' | 'systems' | 'vendors' | 'vehicles' | 'financial' | 'documents';
type MaintenanceFilter = 'all' | 'overdue' | 'due-soon' | 'upcoming' | 'completed';
type ViewMode = 'cards' | 'list' | 'timeline';

interface ServiceRecord {
  id: string;
  date: string;
  type: 'scheduled' | 'repair' | 'inspection' | 'installation' | 'replacement' | 'oil-change' | 'tire' | 'brake';
  description: string;
  vendor: { id: string; name: string; phone: string };
  cost?: number;
  notes?: string;
  mileage?: number;
  documents?: { id: string; name: string; url: string }[];
  technicianName?: string;
}

interface MaintenanceSchedule {
  interval: string;
  intervalDays: number;
  lastService: string;
  nextService: string;
  status: 'overdue' | 'due-soon' | 'upcoming' | 'on-track';
  daysUntilDue: number;
}

interface HomeSystem {
  id: string;
  name: string;
  category: 'hvac' | 'plumbing' | 'electrical' | 'appliance' | 'exterior' | 'security' | 'pool' | 'lawn' | 'other';
  type: string;
  location?: string;
  brand?: string;
  model?: string;
  serialNumber?: string;
  installDate?: string;
  installYear?: number;
  expectedLifespan?: number;
  purchaseDate?: string;
  purchasePrice?: number;
  warrantyExpiry?: string;
  warrantyProvider?: string;
  condition: 'excellent' | 'good' | 'fair' | 'needs-attention' | 'unknown';
  maintenance?: MaintenanceSchedule;
  serviceHistory?: ServiceRecord[];
  assignedVendor?: { id: string; name: string; phone: string; email?: string; isPreferred: boolean };
  documents?: { id: string; name: string; type: string; url: string; uploadDate: string }[];
  notes?: string;
  tags?: string[];
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
  systemsServiced: string[];
}

interface Vehicle {
  id: string;
  nickname: string;
  year: number;
  make: string;
  model: string;
  trim?: string;
  color: string;
  vin: string;
  licensePlate: string;
  state: string;
  mileage: number;
  fuelType: string;
  ownership: 'owned' | 'financed' | 'leased';
  purchaseDate?: string;
  purchasePrice?: number;
  registrationExpiry: string;
  registrationCost?: number;
  inspectionExpiry?: string;
  inspectionType?: string;
  insuranceProvider: string;
  insurancePolicy: string;
  insuranceExpiry: string;
  insurancePremium: number;
  insuranceFrequency: string;
  insuranceDeductible?: number;
  hasLoan: boolean;
  loanProvider?: string;
  loanBalance?: number;
  loanMonthlyPayment?: number;
  loanInterestRate?: number;
  loanMaturityDate?: string;
  primaryServiceProvider?: { name: string; phone: string; address?: string };
  oilChangeInterval?: string;
  lastOilChange?: string;
  nextOilChange?: string;
  serviceHistory: ServiceRecord[];
  documents: { id: string; name: string; type: string; url: string; uploadDate: string }[];
  photoUrl?: string;
  notes?: string;
}

interface Loan {
  id: string;
  type: 'mortgage' | 'heloc' | 'auto' | 'student' | 'personal' | 'other';
  subtype?: string;
  nickname: string;
  lender: string;
  accountNumber: string;
  originalAmount: number;
  currentBalance: number;
  interestRate: number;
  interestType: 'fixed' | 'variable';
  monthlyPayment: number;
  paymentDueDay: number;
  nextPaymentDate: string;
  maturityDate?: string;
  startDate?: string;
  propertyAddress?: string;
  vehicleId?: string;
  paidAmount: number;
  percentPaid: number;
  remainingPayments?: number;
  includesEscrow?: boolean;
  escrowAmount?: number;
  propertyTaxAmount?: number;
  homeownersInsuranceAmount?: number;
  autopayEnabled: boolean;
  paymentMethod?: string;
  lenderPhone?: string;
  lenderWebsite?: string;
  notes?: string;
}

interface InsurancePolicy {
  id: string;
  type: 'homeowners' | 'auto' | 'umbrella' | 'life' | 'other';
  provider: string;
  policyNumber: string;
  premium: number;
  premiumFrequency: 'monthly' | 'quarterly' | 'semi-annual' | 'annual';
  deductible?: number;
  coverage?: number;
  coverageDetails?: string[];
  effectiveDate: string;
  expiryDate: string;
  autoRenew: boolean;
  paymentMethod?: string;
  agentName?: string;
  agentPhone?: string;
  agentEmail?: string;
  coveredItems?: string[];
  notes?: string;
}

interface PropertyTax {
  id: string;
  propertyAddress: string;
  jurisdiction: string;
  annualAmount: number;
  paymentSchedule: string;
  nextPaymentDate: string;
  nextPaymentAmount: number;
  assessedValue: number;
  taxRate: number;
  paidThroughEscrow: boolean;
  paymentHistory: { date: string; amount: number; period: string }[];
}

interface Document {
  id: string;
  name: string;
  category: string;
  subcategory?: string;
  description?: string;
  uploadDate: string;
  fileType: string;
  fileSize: string;
  url: string;
  tags?: string[];
  expiryDate?: string;
  linkedTo?: { type: string; id: string; name: string };
  isFavorite?: boolean;
}

// ============================================================================
// PROPERTY DATA
// ============================================================================

const PROPERTY = {
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
  photoUrl: '/images/homes/38-bedford-rd.jpg',
  purchaseDate: 'June 15, 2019',
  purchasePrice: 2495000,
  currentValue: 3150000,
};

// ============================================================================
// SYSTEMS DATA
// ============================================================================

const HOME_SYSTEMS: HomeSystem[] = [
  {
    id: 'hvac-ac',
    name: 'Central Air Conditioning',
    category: 'hvac',
    type: 'Split System Central AC',
    location: 'Basement mechanical room',
    brand: 'Carrier',
    model: 'Infinity 26',
    serialNumber: 'CAR-2021-INF26-48291',
    installDate: 'March 15, 2021',
    installYear: 2021,
    expectedLifespan: 15,
    purchasePrice: 8500,
    warrantyExpiry: 'March 15, 2031',
    warrantyProvider: 'Carrier',
    condition: 'excellent',
    maintenance: {
      interval: 'Every 3 months',
      intervalDays: 90,
      lastService: 'October 15, 2024',
      nextService: 'January 15, 2025',
      status: 'due-soon',
      daysUntilDue: 23,
    },
    serviceHistory: [
      {
        id: 'sh-1',
        date: 'October 15, 2024',
        type: 'scheduled',
        description: 'Fall maintenance - cleaned coils, checked refrigerant levels, replaced filter',
        vendor: { id: 'v-1', name: 'Comfort Zone HVAC', phone: '(203) 555-2665' },
        cost: 189,
        technicianName: 'Mike Rodriguez',
      },
    ],
    assignedVendor: {
      id: 'v-1',
      name: 'Comfort Zone HVAC',
      phone: '(203) 555-2665',
      email: 'service@comfortzonehvac.com',
      isPreferred: true,
    },
    notes: 'System handles 3 zones. Upstairs zone runs warmer - may need balancing.',
  },
  {
    id: 'hvac-furnace',
    name: 'Gas Furnace',
    category: 'hvac',
    type: 'High-Efficiency Gas Furnace',
    location: 'Basement mechanical room',
    brand: 'Carrier',
    model: 'Infinity 98',
    installYear: 2021,
    expectedLifespan: 20,
    condition: 'excellent',
    warrantyExpiry: 'March 15, 2031',
    maintenance: {
      interval: 'Annually',
      intervalDays: 365,
      lastService: 'October 15, 2024',
      nextService: 'October 15, 2025',
      status: 'on-track',
      daysUntilDue: 296,
    },
    assignedVendor: { id: 'v-1', name: 'Comfort Zone HVAC', phone: '(203) 555-2665', isPreferred: true },
  },
  {
    id: 'plumb-waterheater',
    name: 'Tankless Water Heater',
    category: 'plumbing',
    type: 'Tankless Gas',
    location: 'Basement utility room',
    brand: 'Rinnai',
    model: 'RU199iN',
    installYear: 2020,
    expectedLifespan: 20,
    condition: 'good',
    warrantyExpiry: 'August 10, 2032',
    maintenance: {
      interval: 'Annually',
      intervalDays: 365,
      lastService: 'August 15, 2024',
      nextService: 'August 15, 2025',
      status: 'on-track',
      daysUntilDue: 235,
    },
    assignedVendor: { id: 'v-2', name: "Mike's Plumbing", phone: '(203) 555-7473', isPreferred: true },
  },
  {
    id: 'plumb-softener',
    name: 'Water Softener',
    category: 'plumbing',
    type: 'Whole House Water Softener',
    brand: 'Kinetico',
    model: 'Premier Series S650',
    installYear: 2022,
    expectedLifespan: 15,
    condition: 'excellent',
    warrantyExpiry: 'January 15, 2032',
    maintenance: {
      interval: 'Every 6 months',
      intervalDays: 180,
      lastService: 'July 20, 2024',
      nextService: 'January 20, 2025',
      status: 'due-soon',
      daysUntilDue: 28,
    },
    assignedVendor: { id: 'v-2', name: "Mike's Plumbing", phone: '(203) 555-7473', isPreferred: true },
  },
  {
    id: 'elec-generator',
    name: 'Whole Home Generator',
    category: 'electrical',
    type: 'Standby Generator',
    brand: 'Generac',
    model: 'Guardian 24kW',
    installYear: 2019,
    expectedLifespan: 25,
    condition: 'excellent',
    warrantyExpiry: 'November 10, 2026',
    maintenance: {
      interval: 'Every 6 months',
      intervalDays: 180,
      lastService: 'November 5, 2024',
      nextService: 'May 5, 2025',
      status: 'on-track',
      daysUntilDue: 133,
    },
    assignedVendor: { id: 'v-3', name: 'Tesla Certified Electricians', phone: '(203) 555-8658', isPreferred: true },
  },
  {
    id: 'elec-panel',
    name: 'Electrical Panel',
    category: 'electrical',
    type: 'Main Service Panel',
    brand: 'Square D',
    model: 'QO 200A',
    location: 'Garage',
    installYear: 2015,
    expectedLifespan: 40,
    condition: 'excellent',
    maintenance: {
      interval: 'Every 3 years',
      intervalDays: 1095,
      lastService: 'December 12, 2023',
      nextService: 'December 12, 2026',
      status: 'on-track',
      daysUntilDue: 718,
    },
    assignedVendor: { id: 'v-3', name: 'Tesla Certified Electricians', phone: '(203) 555-8658', isPreferred: true },
  },
  {
    id: 'pool-main',
    name: 'Swimming Pool',
    category: 'pool',
    type: 'In-Ground Gunite (Saltwater)',
    installYear: 2010,
    expectedLifespan: 50,
    condition: 'excellent',
    maintenance: {
      interval: 'Weekly (in season)',
      intervalDays: 7,
      lastService: 'October 15, 2024',
      nextService: 'May 1, 2025',
      status: 'on-track',
      daysUntilDue: 129,
    },
    assignedVendor: { id: 'v-4', name: 'Pool Paradise CT', phone: '(203) 555-7665', isPreferred: true },
  },
  {
    id: 'pool-pump',
    name: 'Pool Pump & Filter',
    category: 'pool',
    type: 'Variable Speed Pump',
    brand: 'Pentair',
    model: 'IntelliFlo VSF',
    location: 'Pool equipment pad',
    installYear: 2021,
    expectedLifespan: 10,
    condition: 'good',
    maintenance: {
      interval: 'Monthly (in season)',
      intervalDays: 30,
      lastService: 'September 20, 2024',
      nextService: 'May 1, 2025',
      status: 'on-track',
      daysUntilDue: 129,
    },
    assignedVendor: { id: 'v-4', name: 'Pool Paradise CT', phone: '(203) 555-7665', isPreferred: true },
  },
  {
    id: 'ext-roof',
    name: 'Roof System',
    category: 'exterior',
    type: 'Asphalt Shingle',
    brand: 'GAF',
    model: 'Timberline HDZ',
    installYear: 2018,
    expectedLifespan: 30,
    condition: 'excellent',
    maintenance: {
      interval: 'Annually',
      intervalDays: 365,
      lastService: 'November 15, 2024',
      nextService: 'November 15, 2025',
      status: 'on-track',
      daysUntilDue: 326,
    },
    assignedVendor: { id: 'v-6', name: 'ABC Roofing', phone: '(203) 555-7667', isPreferred: true },
  },
  {
    id: 'ext-gutters',
    name: 'Gutters & Downspouts',
    category: 'exterior',
    type: 'Seamless Aluminum',
    installYear: 2018,
    expectedLifespan: 25,
    condition: 'good',
    maintenance: {
      interval: 'Twice yearly',
      intervalDays: 180,
      lastService: 'November 10, 2024',
      nextService: 'April 10, 2025',
      status: 'on-track',
      daysUntilDue: 108,
    },
  },
  {
    id: 'lawn-irrigation',
    name: 'Irrigation System',
    category: 'lawn',
    type: 'In-Ground Sprinkler System',
    brand: 'Rain Bird',
    model: 'ESP-TM2',
    installYear: 2017,
    expectedLifespan: 20,
    condition: 'good',
    maintenance: {
      interval: 'Spring/Fall',
      intervalDays: 180,
      lastService: 'October 28, 2024',
      nextService: 'April 15, 2025',
      status: 'on-track',
      daysUntilDue: 113,
    },
    assignedVendor: { id: 'v-5', name: 'Greenwich Landscaping', phone: '(203) 555-5263', isPreferred: true },
  },
  {
    id: 'appl-refrigerator',
    name: 'Kitchen Refrigerator',
    category: 'appliance',
    type: 'Built-In French Door',
    brand: 'Sub-Zero',
    model: 'BI-36U',
    location: 'Kitchen',
    installYear: 2020,
    expectedLifespan: 20,
    condition: 'excellent',
    warrantyExpiry: 'July 1, 2025',
    maintenance: {
      interval: 'Every 6 months',
      intervalDays: 180,
      lastService: 'June 15, 2024',
      nextService: 'December 15, 2024',
      status: 'overdue',
      daysUntilDue: -9,
    },
  },
  {
    id: 'appl-washer',
    name: 'Washer',
    category: 'appliance',
    type: 'Front Load',
    brand: 'Miele',
    model: 'W1',
    location: 'Laundry Room',
    installYear: 2023,
    expectedLifespan: 12,
    condition: 'excellent',
    warrantyExpiry: 'January 20, 2026',
    maintenance: {
      interval: 'Monthly',
      intervalDays: 30,
      lastService: 'December 1, 2024',
      nextService: 'January 1, 2025',
      status: 'due-soon',
      daysUntilDue: 9,
    },
  },
  {
    id: 'appl-dryer',
    name: 'Dryer',
    category: 'appliance',
    type: 'Heat Pump Dryer',
    brand: 'Miele',
    model: 'T1',
    location: 'Laundry Room',
    installYear: 2023,
    expectedLifespan: 12,
    condition: 'excellent',
    warrantyExpiry: 'January 20, 2026',
    maintenance: {
      interval: 'Every 3 months',
      intervalDays: 90,
      lastService: 'November 1, 2024',
      nextService: 'February 1, 2025',
      status: 'on-track',
      daysUntilDue: 40,
    },
  },
  {
    id: 'sec-alarm',
    name: 'Security System',
    category: 'security',
    type: 'Monitored Alarm System',
    brand: 'ADT',
    model: 'Command Panel',
    installYear: 2019,
    expectedLifespan: 15,
    condition: 'excellent',
    maintenance: {
      interval: 'Annually',
      intervalDays: 365,
      lastService: 'September 10, 2024',
      nextService: 'September 10, 2025',
      status: 'on-track',
      daysUntilDue: 260,
    },
  },
  {
    id: 'sec-cameras',
    name: 'Security Cameras',
    category: 'security',
    type: 'IP Camera System',
    brand: 'Ubiquiti',
    model: 'UniFi Protect',
    installYear: 2022,
    expectedLifespan: 10,
    condition: 'excellent',
    maintenance: {
      interval: 'Every 6 months',
      intervalDays: 180,
      lastService: 'October 5, 2024',
      nextService: 'April 5, 2025',
      status: 'on-track',
      daysUntilDue: 103,
    },
  },
];

// ============================================================================
// VENDORS DATA
// ============================================================================

const VENDORS: Vendor[] = [
  {
    id: 'v-1',
    name: 'Comfort Zone HVAC',
    category: 'HVAC',
    phone: '(203) 555-2665',
    email: 'service@comfortzonehvac.com',
    website: 'www.comfortzonehvac.com',
    rating: 4.9,
    reviewCount: 127,
    lastUsed: 'October 2024',
    totalSpent: 3850,
    isPreferred: true,
    servicesProvided: ['HVAC Maintenance', 'AC Repair', 'Furnace Service'],
    systemsServiced: ['hvac-ac', 'hvac-furnace'],
    notes: 'Ask for Mike Rodriguez - he knows our system well.',
  },
  {
    id: 'v-2',
    name: "Mike's Plumbing",
    category: 'Plumbing',
    phone: '(203) 555-7473',
    email: 'mike@mikesplumbing.com',
    rating: 4.8,
    reviewCount: 89,
    lastUsed: 'August 2024',
    totalSpent: 4250,
    isPreferred: true,
    servicesProvided: ['Plumbing Repair', 'Water Heater', 'Water Treatment'],
    systemsServiced: ['plumb-waterheater', 'plumb-softener'],
  },
  {
    id: 'v-3',
    name: 'Tesla Certified Electricians',
    category: 'Electrical',
    phone: '(203) 555-8658',
    rating: 4.9,
    reviewCount: 156,
    lastUsed: 'November 2024',
    totalSpent: 16500,
    isPreferred: true,
    servicesProvided: ['Generator Service', 'EV Charger', 'Electrical Panel'],
    systemsServiced: ['elec-generator'],
  },
  {
    id: 'v-4',
    name: 'Pool Paradise CT',
    category: 'Pool',
    phone: '(203) 555-7665',
    rating: 4.7,
    reviewCount: 203,
    lastUsed: 'October 2024',
    totalSpent: 5800,
    isPreferred: true,
    servicesProvided: ['Weekly Pool Service', 'Opening/Closing', 'Equipment Repair'],
    systemsServiced: ['pool-main'],
  },
  {
    id: 'v-5',
    name: 'Greenwich Landscaping',
    category: 'Landscaping',
    phone: '(203) 555-5263',
    rating: 4.6,
    reviewCount: 312,
    lastUsed: 'November 2024',
    totalSpent: 14500,
    isPreferred: true,
    servicesProvided: ['Lawn Care', 'Snow Removal', 'Irrigation'],
    systemsServiced: [],
  },
];

// ============================================================================
// VEHICLES DATA
// ============================================================================

const VEHICLES: Vehicle[] = [
  {
    id: 'veh-1',
    nickname: "Bob's Tesla",
    year: 2023,
    make: 'Tesla',
    model: 'Model Y',
    trim: 'Long Range AWD',
    color: 'Pearl White Multi-Coat',
    vin: '5YJ3E1EA8PF123456',
    licensePlate: 'AB-12345',
    state: 'CT',
    mileage: 24500,
    fuelType: 'Electric',
    ownership: 'financed',
    purchaseDate: 'January 15, 2023',
    purchasePrice: 65990,
    registrationExpiry: 'March 15, 2025',
    registrationCost: 475,
    inspectionType: 'Emissions exempt (EV)',
    insuranceProvider: 'Chubb',
    insurancePolicy: 'AUTO-887429-01',
    insuranceExpiry: 'September 1, 2025',
    insurancePremium: 1800,
    insuranceFrequency: 'annual',
    insuranceDeductible: 500,
    hasLoan: true,
    loanProvider: 'Tesla Financing',
    loanBalance: 42000,
    loanMonthlyPayment: 1150,
    loanInterestRate: 4.99,
    loanMaturityDate: 'January 15, 2028',
    primaryServiceProvider: { name: 'Tesla Service Center', phone: '(888) 518-3752', address: '411 West Putnam Ave, Greenwich, CT' },
    oilChangeInterval: 'N/A - Electric',
    serviceHistory: [
      {
        id: 'vs-1',
        date: 'July 15, 2024',
        type: 'scheduled',
        description: 'Annual service - tire rotation, brake inspection, cabin filter replacement',
        vendor: { id: 'tesla-svc', name: 'Tesla Service Center', phone: '(888) 518-3752' },
        cost: 250,
        mileage: 18500,
      },
    ],
    documents: [
      { id: 'vd-1', name: 'Tesla Title', type: 'title', url: '#', uploadDate: 'Jan 2023' },
      { id: 'vd-2', name: 'Bill of Sale', type: 'receipt', url: '#', uploadDate: 'Jan 2023' },
      { id: 'vd-3', name: 'CT Registration', type: 'registration', url: '#', uploadDate: 'Mar 2024' },
      { id: 'vd-4', name: 'Insurance Card', type: 'insurance', url: '#', uploadDate: 'Sep 2024' },
      { id: 'vd-5', name: 'Loan Agreement', type: 'loan', url: '#', uploadDate: 'Jan 2023' },
    ],
    photoUrl: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=400',
    notes: 'Charging at home with Wall Connector. Supercharger network for road trips.',
  },
  {
    id: 'veh-2',
    nickname: 'Family Highlander',
    year: 2022,
    make: 'Toyota',
    model: 'Highlander Hybrid',
    trim: 'Platinum AWD',
    color: 'Celestial Silver Metallic',
    vin: '5TDZBRCH7NS123456',
    licensePlate: 'CD-67890',
    state: 'CT',
    mileage: 35200,
    fuelType: 'Hybrid',
    ownership: 'owned',
    purchaseDate: 'August 10, 2022',
    purchasePrice: 52450,
    registrationExpiry: 'June 30, 2025',
    registrationCost: 525,
    inspectionExpiry: 'June 30, 2025',
    inspectionType: 'Emissions',
    insuranceProvider: 'Chubb',
    insurancePolicy: 'AUTO-887429-02',
    insuranceExpiry: 'September 1, 2025',
    insurancePremium: 1600,
    insuranceFrequency: 'annual',
    insuranceDeductible: 500,
    hasLoan: false,
    primaryServiceProvider: { name: 'Greenwich Toyota', phone: '(203) 555-8700', address: '275 West Putnam Ave, Greenwich, CT' },
    oilChangeInterval: 'Every 10,000 miles',
    lastOilChange: 'August 20, 2024',
    nextOilChange: 'February 2025',
    serviceHistory: [
      {
        id: 'vs-3',
        date: 'August 20, 2024',
        type: 'oil-change',
        description: 'Synthetic oil change, tire rotation, multi-point inspection',
        vendor: { id: 'toyota', name: 'Greenwich Toyota', phone: '(203) 555-8700' },
        cost: 185,
        mileage: 32100,
      },
      {
        id: 'vs-4',
        date: 'February 15, 2024',
        type: 'oil-change',
        description: 'Synthetic oil change, brake inspection',
        vendor: { id: 'toyota', name: 'Greenwich Toyota', phone: '(203) 555-8700' },
        cost: 95,
        mileage: 25800,
      },
    ],
    documents: [
      { id: 'vd-7', name: 'Toyota Title (Clear)', type: 'title', url: '#', uploadDate: 'Aug 2024' },
      { id: 'vd-8', name: 'CT Registration', type: 'registration', url: '#', uploadDate: 'Jun 2024' },
      { id: 'vd-9', name: 'Insurance Card', type: 'insurance', url: '#', uploadDate: 'Sep 2024' },
      { id: 'vd-10', name: 'Owners Manual', type: 'manual', url: '#', uploadDate: 'Aug 2022' },
    ],
    notes: 'Primary family vehicle. ToyotaCare prepaid maintenance expired Aug 2024.',
  },
  {
    id: 'veh-3',
    nickname: "Alice's Mercedes",
    year: 2024,
    make: 'Mercedes-Benz',
    model: 'GLE 450',
    trim: '4MATIC',
    color: 'Obsidian Black Metallic',
    vin: '4JGFB4KB7RA123456',
    licensePlate: 'EF-11111',
    state: 'CT',
    mileage: 8750,
    fuelType: 'Gasoline',
    ownership: 'leased',
    purchaseDate: 'September 1, 2024',
    registrationExpiry: 'September 1, 2025',
    registrationCost: 585,
    inspectionExpiry: 'September 1, 2025',
    inspectionType: 'Emissions',
    insuranceProvider: 'Chubb',
    insurancePolicy: 'AUTO-887429-03',
    insuranceExpiry: 'September 1, 2025',
    insurancePremium: 2200,
    insuranceFrequency: 'annual',
    insuranceDeductible: 500,
    hasLoan: true,
    loanProvider: 'Mercedes-Benz Financial Services',
    loanBalance: 68000,
    loanMonthlyPayment: 899,
    loanInterestRate: 5.49,
    loanMaturityDate: 'September 1, 2027',
    primaryServiceProvider: { name: 'Mercedes-Benz of Greenwich', phone: '(203) 555-9200' },
    oilChangeInterval: 'Every 10,000 miles or 1 year',
    lastOilChange: 'September 10, 2024',
    nextOilChange: 'September 2025',
    serviceHistory: [
      {
        id: 'vs-6',
        date: 'September 10, 2024',
        type: 'scheduled',
        description: 'Service A - synthetic oil change, filter replacement',
        vendor: { id: 'mbenz', name: 'Mercedes-Benz of Greenwich', phone: '(203) 555-9200' },
        cost: 0,
        mileage: 5200,
        notes: 'Covered under prepaid maintenance',
      },
    ],
    documents: [
      { id: 'vd-12', name: 'Lease Agreement', type: 'lease', url: '#', uploadDate: 'Sep 2024' },
      { id: 'vd-13', name: 'CT Registration', type: 'registration', url: '#', uploadDate: 'Sep 2024' },
      { id: 'vd-14', name: 'Insurance Card', type: 'insurance', url: '#', uploadDate: 'Sep 2024' },
    ],
    notes: '36-month lease, 10,000 mi/year. Prepaid maintenance included.',
  },
];

// ============================================================================
// LOANS DATA
// ============================================================================

const LOANS: Loan[] = [
  {
    id: 'loan-1',
    type: 'mortgage',
    subtype: '30-Year Fixed',
    nickname: 'Primary Mortgage',
    lender: 'First Republic Bank',
    accountNumber: '****7891',
    originalAmount: 1750000,
    currentBalance: 1425000,
    paidAmount: 325000,
    percentPaid: 18.6,
    interestRate: 3.125,
    interestType: 'fixed',
    monthlyPayment: 7498,
    paymentDueDay: 1,
    nextPaymentDate: 'January 1, 2025',
    maturityDate: 'June 1, 2049',
    startDate: 'June 15, 2019',
    remainingPayments: 294,
    propertyAddress: '38 Bedford Road, Greenwich, CT 06831',
    includesEscrow: true,
    escrowAmount: 2850,
    propertyTaxAmount: 24500,
    homeownersInsuranceAmount: 12500,
    autopayEnabled: true,
    paymentMethod: 'Bank Transfer from Chase ****4521',
    lenderPhone: '(800) 392-1400',
    lenderWebsite: 'www.firstrepublic.com',
    notes: 'Refinanced in 2021 from 3.75% to 3.125%. Excellent rate to keep.',
  },
  {
    id: 'loan-2',
    type: 'heloc',
    nickname: 'Home Equity Line',
    lender: 'First Republic Bank',
    accountNumber: '****7892',
    originalAmount: 500000,
    currentBalance: 125000,
    paidAmount: 375000,
    percentPaid: 75,
    interestRate: 7.25,
    interestType: 'variable',
    monthlyPayment: 756,
    paymentDueDay: 15,
    nextPaymentDate: 'January 15, 2025',
    maturityDate: 'June 15, 2034',
    startDate: 'June 15, 2019',
    remainingPayments: 114,
    propertyAddress: '38 Bedford Road, Greenwich, CT 06831',
    autopayEnabled: true,
    paymentMethod: 'Bank Transfer from Chase ****4521',
    lenderPhone: '(800) 392-1400',
    notes: 'Variable rate tied to Prime. Used for pool renovation and kitchen remodel.',
  },
  {
    id: 'loan-3',
    type: 'auto',
    nickname: 'Tesla Model Y Loan',
    lender: 'Tesla Financing',
    accountNumber: '****4521',
    originalAmount: 65000,
    currentBalance: 42000,
    paidAmount: 23000,
    percentPaid: 35.4,
    interestRate: 4.99,
    interestType: 'fixed',
    monthlyPayment: 1150,
    paymentDueDay: 15,
    nextPaymentDate: 'January 15, 2025',
    maturityDate: 'January 15, 2028',
    startDate: 'January 15, 2023',
    remainingPayments: 37,
    vehicleId: 'veh-1',
    autopayEnabled: true,
    paymentMethod: 'Bank Transfer from Chase ****4521',
    lenderPhone: '(888) 518-3752',
    notes: '60-month term. Could pay off early without penalty.',
  },
  {
    id: 'loan-4',
    type: 'student',
    nickname: 'MBA Student Loans',
    lender: 'SoFi',
    accountNumber: '****2847',
    originalAmount: 85000,
    currentBalance: 34200,
    paidAmount: 50800,
    percentPaid: 59.8,
    interestRate: 4.25,
    interestType: 'fixed',
    monthlyPayment: 875,
    paymentDueDay: 20,
    nextPaymentDate: 'January 20, 2025',
    maturityDate: 'March 20, 2028',
    startDate: 'March 20, 2018',
    remainingPayments: 39,
    autopayEnabled: true,
    paymentMethod: 'Bank Transfer from Chase ****4521',
    lenderPhone: '(855) 456-7634',
    notes: 'Refinanced from federal loans in 2020. Autopay discount of 0.25% applied.',
  },
  {
    id: 'loan-5',
    type: 'auto',
    subtype: 'Lease',
    nickname: 'Mercedes GLE Lease',
    lender: 'Mercedes-Benz Financial',
    accountNumber: '****7890',
    originalAmount: 72000,
    currentBalance: 68000,
    paidAmount: 4000,
    percentPaid: 5.6,
    interestRate: 5.49,
    interestType: 'fixed',
    monthlyPayment: 899,
    paymentDueDay: 1,
    nextPaymentDate: 'January 1, 2025',
    maturityDate: 'September 1, 2027',
    startDate: 'September 1, 2024',
    remainingPayments: 33,
    vehicleId: 'veh-3',
    autopayEnabled: true,
    paymentMethod: 'Bank Transfer from Chase ****4521',
    lenderPhone: '(800) 654-6222',
    notes: '36-month lease, 10,000 mi/year. $0.25/mile over.',
  },
];

// ============================================================================
// INSURANCE POLICIES DATA
// ============================================================================

const INSURANCE_POLICIES: InsurancePolicy[] = [
  {
    id: 'ins-1',
    type: 'homeowners',
    provider: 'Chubb',
    policyNumber: 'HO-8847291-CT',
    premium: 12500,
    premiumFrequency: 'annual',
    deductible: 10000,
    coverage: 4500000,
    coverageDetails: [
      'Dwelling: $4,500,000',
      'Personal Property: $2,250,000',
      'Personal Liability: $1,000,000',
      'Loss of Use: $900,000',
    ],
    effectiveDate: 'June 15, 2024',
    expiryDate: 'June 15, 2025',
    autoRenew: true,
    paymentMethod: 'Paid through escrow',
    agentName: 'David Chen',
    agentPhone: '(203) 555-2482',
    agentEmail: 'david.chen@chubbagent.com',
    notes: 'Scheduled riders for jewelry ($150K) and fine art ($75K).',
  },
  {
    id: 'ins-2',
    type: 'auto',
    provider: 'Chubb',
    policyNumber: 'AUTO-887429',
    premium: 5600,
    premiumFrequency: 'annual',
    deductible: 500,
    coverageDetails: [
      'Bodily Injury: $500K/$1M',
      'Property Damage: $250,000',
      'Comprehensive: $500 ded',
      'Collision: $500 ded',
    ],
    effectiveDate: 'September 1, 2024',
    expiryDate: 'September 1, 2025',
    autoRenew: true,
    paymentMethod: 'Annual via credit card',
    agentName: 'David Chen',
    agentPhone: '(203) 555-2482',
    coveredItems: ['2023 Tesla Model Y', '2022 Toyota Highlander', '2024 Mercedes GLE 450'],
  },
  {
    id: 'ins-3',
    type: 'umbrella',
    provider: 'Chubb',
    policyNumber: 'UMB-112847',
    premium: 1500,
    premiumFrequency: 'annual',
    coverage: 5000000,
    coverageDetails: ['Personal Umbrella: $5,000,000', 'Excess over home and auto'],
    effectiveDate: 'June 15, 2024',
    expiryDate: 'June 15, 2025',
    autoRenew: true,
    agentName: 'David Chen',
    agentPhone: '(203) 555-2482',
  },
  {
    id: 'ins-4',
    type: 'life',
    provider: 'Northwestern Mutual',
    policyNumber: 'LF-44892711',
    premium: 2400,
    premiumFrequency: 'annual',
    coverage: 2000000,
    coverageDetails: ['Death Benefit: $2,000,000', 'Term: 20-year level', 'Insured: Bob Morrison'],
    effectiveDate: 'March 1, 2020',
    expiryDate: 'March 1, 2040',
    autoRenew: false,
    agentName: 'Sarah Williams',
    agentPhone: '(203) 555-8900',
    agentEmail: 'sarah.williams@nm.com',
  },
];

// ============================================================================
// PROPERTY TAX DATA
// ============================================================================

const PROPERTY_TAX: PropertyTax = {
  id: 'ptax-1',
  propertyAddress: '38 Bedford Road, Greenwich, CT 06831',
  jurisdiction: 'Town of Greenwich',
  annualAmount: 24500,
  paymentSchedule: 'semi-annual',
  nextPaymentDate: 'January 1, 2025',
  nextPaymentAmount: 12250,
  assessedValue: 2850000,
  taxRate: 11.59,
  paidThroughEscrow: true,
  paymentHistory: [
    { date: 'July 1, 2024', amount: 12250, period: 'Jul-Dec 2024' },
    { date: 'January 1, 2024', amount: 12000, period: 'Jan-Jun 2024' },
    { date: 'July 1, 2023', amount: 12000, period: 'Jul-Dec 2023' },
  ],
};

// ============================================================================
// DOCUMENTS DATA
// ============================================================================

const DOCUMENTS: Document[] = [
  // Property
  { id: 'doc-1', name: 'Property Deed', category: 'Property', subcategory: 'Ownership', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '1.1 MB', url: '#', isFavorite: true },
  { id: 'doc-2', name: 'Survey & Plot Plan', category: 'Property', subcategory: 'Ownership', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '4.2 MB', url: '#' },
  { id: 'doc-3', name: 'Title Insurance Policy', category: 'Property', subcategory: 'Ownership', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '2.8 MB', url: '#' },
  { id: 'doc-4', name: 'Purchase Agreement', category: 'Property', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '3.1 MB', url: '#' },
  { id: 'doc-5', name: 'Closing Documents', category: 'Property', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '8.5 MB', url: '#' },
  { id: 'doc-6', name: 'Home Inspection Report', category: 'Property', uploadDate: 'May 2019', fileType: 'pdf', fileSize: '12.3 MB', url: '#' },
  // Financial
  { id: 'doc-7', name: 'Mortgage Note', category: 'Financial', subcategory: 'Mortgage', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '2.4 MB', url: '#', linkedTo: { type: 'loan', id: 'loan-1', name: 'Primary Mortgage' } },
  { id: 'doc-8', name: 'Mortgage Statement - Dec 2024', category: 'Financial', uploadDate: 'Dec 2024', fileType: 'pdf', fileSize: '156 KB', url: '#' },
  { id: 'doc-9', name: 'HELOC Agreement', category: 'Financial', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '1.8 MB', url: '#' },
  { id: 'doc-10', name: 'Property Tax Bill 2024-2025', category: 'Financial', uploadDate: 'Jul 2024', fileType: 'pdf', fileSize: '245 KB', url: '#' },
  // Insurance
  { id: 'doc-12', name: 'Homeowners Insurance Policy', category: 'Insurance', uploadDate: 'Jun 2024', fileType: 'pdf', fileSize: '2.4 MB', url: '#', expiryDate: 'June 15, 2025', isFavorite: true },
  { id: 'doc-13', name: 'Auto Insurance Policy', category: 'Insurance', uploadDate: 'Sep 2024', fileType: 'pdf', fileSize: '1.5 MB', url: '#', expiryDate: 'September 1, 2025' },
  { id: 'doc-14', name: 'Umbrella Policy', category: 'Insurance', uploadDate: 'Jun 2024', fileType: 'pdf', fileSize: '890 KB', url: '#', expiryDate: 'June 15, 2025' },
  { id: 'doc-16', name: 'Insurance Cards - All Vehicles', category: 'Insurance', uploadDate: 'Sep 2024', fileType: 'pdf', fileSize: '156 KB', url: '#', isFavorite: true },
  // Warranties & Manuals
  { id: 'doc-17', name: 'HVAC Warranty Certificate', category: 'Warranties', uploadDate: 'Mar 2021', fileType: 'pdf', fileSize: '856 KB', url: '#', expiryDate: 'March 15, 2031' },
  { id: 'doc-18', name: 'Generator Warranty', category: 'Warranties', uploadDate: 'Nov 2021', fileType: 'pdf', fileSize: '1.2 MB', url: '#', expiryDate: 'November 10, 2026' },
  { id: 'doc-19', name: 'Sub-Zero Refrigerator Manual', category: 'Manuals', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '5.6 MB', url: '#' },
  { id: 'doc-20', name: 'Pool Equipment Manual', category: 'Manuals', uploadDate: 'May 2018', fileType: 'pdf', fileSize: '8.2 MB', url: '#' },
  // Maintenance
  { id: 'doc-21', name: 'Roof Inspection Report 2024', category: 'Maintenance', uploadDate: 'Sep 2024', fileType: 'pdf', fileSize: '1.8 MB', url: '#' },
  { id: 'doc-22', name: 'Septic Inspection Report', category: 'Maintenance', uploadDate: 'May 2024', fileType: 'pdf', fileSize: '2.1 MB', url: '#' },
  { id: 'doc-23', name: 'Well Water Test Results', category: 'Maintenance', uploadDate: 'Aug 2024', fileType: 'pdf', fileSize: '456 KB', url: '#' },
  // Vehicles
  { id: 'doc-25', name: 'Tesla Title', category: 'Vehicles', subcategory: 'Tesla Model Y', uploadDate: 'Jan 2023', fileType: 'pdf', fileSize: '245 KB', url: '#' },
  { id: 'doc-26', name: 'Toyota Title (Clear)', category: 'Vehicles', subcategory: 'Toyota Highlander', uploadDate: 'Aug 2024', fileType: 'pdf', fileSize: '234 KB', url: '#' },
  { id: 'doc-27', name: 'Mercedes Lease Agreement', category: 'Vehicles', subcategory: 'Mercedes GLE', uploadDate: 'Sep 2024', fileType: 'pdf', fileSize: '1.8 MB', url: '#' },
  // Projects
  { id: 'doc-28', name: 'Pool Renovation Plans', category: 'Projects', subcategory: '2018 Pool Renovation', uploadDate: 'Apr 2018', fileType: 'pdf', fileSize: '5.6 MB', url: '#' },
  { id: 'doc-29', name: 'Pool Permits & Approvals', category: 'Projects', subcategory: '2018 Pool Renovation', uploadDate: 'Apr 2018', fileType: 'pdf', fileSize: '1.2 MB', url: '#' },
  { id: 'doc-30', name: 'Kitchen Remodel Contract', category: 'Projects', subcategory: '2021 Kitchen Remodel', uploadDate: 'Jan 2021', fileType: 'pdf', fileSize: '2.4 MB', url: '#' },
  { id: 'doc-31', name: 'Kitchen Design Renderings', category: 'Projects', subcategory: '2021 Kitchen Remodel', uploadDate: 'Jan 2021', fileType: 'image', fileSize: '8.4 MB', url: '#' },
  // Additional Insurance
  { id: 'doc-32', name: 'Life Insurance Policy', category: 'Insurance', uploadDate: 'Mar 2020', fileType: 'pdf', fileSize: '1.8 MB', url: '#', expiryDate: 'March 1, 2040' },
  // Additional Financial
  { id: 'doc-33', name: 'Tesla Loan Agreement', category: 'Financial', subcategory: 'Auto Loan', uploadDate: 'Jan 2023', fileType: 'pdf', fileSize: '956 KB', url: '#', linkedTo: { type: 'loan', id: 'loan-3', name: 'Tesla Model Y Loan' } },
  { id: 'doc-34', name: 'SoFi Student Loan Agreement', category: 'Financial', subcategory: 'Student Loan', uploadDate: 'Mar 2020', fileType: 'pdf', fileSize: '1.1 MB', url: '#', linkedTo: { type: 'loan', id: 'loan-4', name: 'MBA Student Loans' } },
  // Additional Maintenance
  { id: 'doc-35', name: 'Chimney Inspection 2024', category: 'Maintenance', uploadDate: 'Oct 2024', fileType: 'pdf', fileSize: '890 KB', url: '#' },
  { id: 'doc-36', name: 'Generator Service Record', category: 'Maintenance', uploadDate: 'Nov 2024', fileType: 'pdf', fileSize: '234 KB', url: '#' },
  // Additional Warranties
  { id: 'doc-37', name: 'Miele Appliance Warranty', category: 'Warranties', uploadDate: 'Jun 2019', fileType: 'pdf', fileSize: '645 KB', url: '#', expiryDate: 'June 15, 2029' },
  { id: 'doc-38', name: 'Pool Equipment Warranty', category: 'Warranties', uploadDate: 'May 2018', fileType: 'pdf', fileSize: '720 KB', url: '#', expiryDate: 'May 1, 2028' },
  // Additional Property
  { id: 'doc-39', name: 'Property Photos - Exterior', category: 'Property', subcategory: 'Photos', uploadDate: 'Jun 2019', fileType: 'image', fileSize: '15.2 MB', url: '#' },
  { id: 'doc-40', name: 'Property Photos - Interior', category: 'Property', subcategory: 'Photos', uploadDate: 'Jun 2019', fileType: 'image', fileSize: '22.4 MB', url: '#' },
];

// ============================================================================
// TABS
// ============================================================================

const TABS: { id: TabId; label: string; icon: React.ElementType }[] = [
  { id: 'overview', label: 'Overview', icon: Home },
  { id: 'maintenance', label: 'Maintenance', icon: Calendar },
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
  const icons: Record<string, any> = {
    hvac: ThermometerSun, plumbing: Droplets, electrical: Zap,
    appliance: Refrigerator, exterior: Home, security: Shield,
    pool: Waves, lawn: TreePine,
  };
  return icons[category] || Wrench;
};

const getCategoryLabel = (category: string) => {
  const labels: Record<string, string> = {
    hvac: 'HVAC & Climate', plumbing: 'Plumbing & Water', electrical: 'Electrical',
    appliance: 'Appliances', exterior: 'Exterior', security: 'Security',
    pool: 'Pool & Spa', lawn: 'Lawn & Landscape',
  };
  return labels[category] || 'Other';
};

const getCategoryColor = (category: string) => {
  const colors: Record<string, { bg: string; text: string }> = {
    hvac: { bg: 'bg-orange-100', text: 'text-orange-600' },
    plumbing: { bg: 'bg-blue-100', text: 'text-blue-600' },
    electrical: { bg: 'bg-yellow-100', text: 'text-yellow-600' },
    appliance: { bg: 'bg-purple-100', text: 'text-purple-600' },
    exterior: { bg: 'bg-green-100', text: 'text-green-600' },
    security: { bg: 'bg-red-100', text: 'text-red-600' },
    pool: { bg: 'bg-cyan-100', text: 'text-cyan-600' },
    lawn: { bg: 'bg-emerald-100', text: 'text-emerald-600' },
  };
  return colors[category] || { bg: 'bg-warm-100', text: 'text-warm-600' };
};

const getStatusConfig = (status: string) => {
  const configs: Record<string, any> = {
    overdue: { bg: 'bg-red-50', border: 'border-red-300', text: 'text-red-700', badge: 'bg-red-100 text-red-700', icon: AlertCircle, label: 'Overdue' },
    'due-soon': { bg: 'bg-amber-50', border: 'border-amber-300', text: 'text-amber-700', badge: 'bg-amber-100 text-amber-700', icon: AlertTriangle, label: 'Due Soon' },
    upcoming: { bg: 'bg-blue-50', border: 'border-blue-200', text: 'text-blue-700', badge: 'bg-blue-100 text-blue-700', icon: Calendar, label: 'Upcoming' },
    'on-track': { bg: 'bg-green-50', border: 'border-green-200', text: 'text-green-700', badge: 'bg-green-100 text-green-700', icon: CheckCircle2, label: 'On Track' },
  };
  return configs[status] || configs['on-track'];
};

const formatDaysUntilDue = (days: number) => {
  if (days < 0) return `${Math.abs(days)} days overdue`;
  if (days === 0) return 'Due today';
  if (days < 7) return `Due in ${days} days`;
  if (days < 30) return `Due in ${Math.floor(days / 7)} weeks`;
  return `Due in ${Math.floor(days / 30)} months`;
};

const formatCurrency = (amount: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(amount);

// ============================================================================
// SYSTEM DETAIL MODAL
// ============================================================================

function SystemDetailModal({ system, onClose }: { system: HomeSystem; onClose: () => void }) {
  const [activeSection, setActiveSection] = useState<'details' | 'history' | 'documents'>('details');
  const status = getStatusConfig(system.maintenance?.status || 'on-track');
  const category = getCategoryColor(system.category);
  const CategoryIcon = getCategoryIcon(system.category);

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-end sm:items-center justify-center p-0 sm:p-4">
        <div className="fixed inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white w-full sm:max-w-2xl sm:rounded-2xl overflow-hidden max-h-[90vh] overflow-y-auto rounded-t-2xl">
          <div className="sticky top-0 bg-white border-b border-warm-200 z-10">
            <div className="p-4 flex items-start justify-between">
              <div className="flex items-start gap-3">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${category.bg}`}>
                  <CategoryIcon className={`w-6 h-6 ${category.text}`} />
                </div>
                <div>
                  <h2 className="text-lg font-bold text-warm-900">{system.name}</h2>
                  <p className="text-sm text-warm-500">{system.type}</p>
                </div>
              </div>
              <button onClick={onClose} className="p-2 hover:bg-warm-100 rounded-lg">
                <X className="w-5 h-5 text-warm-400" />
              </button>
            </div>
            <div className="flex px-4">
              {[{ id: 'details', label: 'Details' }, { id: 'history', label: 'History' }, { id: 'documents', label: 'Documents' }].map(tab => (
                <button
                  key={tab.id}
                  onClick={() => setActiveSection(tab.id as any)}
                  className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${activeSection === tab.id ? 'border-haven-600 text-haven-700' : 'border-transparent text-warm-500'}`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>
          <div className="p-4 space-y-4">
            {activeSection === 'details' && (
              <>
                {system.maintenance && (
                  <div className={`p-4 rounded-xl ${status.bg} border ${status.border}`}>
                    <div className="flex items-center justify-between mb-3">
                      <h3 className={`font-semibold ${status.text}`}>Maintenance Status</h3>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${status.badge}`}>{status.label}</span>
                    </div>
                    <div className="grid grid-cols-2 gap-3 text-sm">
                      <div><p className="text-warm-500 text-xs">Last Service</p><p className="font-medium">{system.maintenance.lastService}</p></div>
                      <div><p className="text-warm-500 text-xs">Next Service</p><p className={`font-medium ${status.text}`}>{system.maintenance.nextService}</p></div>
                      <div><p className="text-warm-500 text-xs">Interval</p><p className="font-medium">{system.maintenance.interval}</p></div>
                      <div><p className="text-warm-500 text-xs">Time Until Due</p><p className={`font-medium ${status.text}`}>{formatDaysUntilDue(system.maintenance.daysUntilDue)}</p></div>
                    </div>
                  </div>
                )}
                <div className="grid grid-cols-2 gap-3">
                  {system.brand && <div className="p-3 bg-warm-50 rounded-lg"><p className="text-xs text-warm-500">Brand</p><p className="font-medium">{system.brand}</p></div>}
                  {system.model && <div className="p-3 bg-warm-50 rounded-lg"><p className="text-xs text-warm-500">Model</p><p className="font-medium">{system.model}</p></div>}
                  {system.warrantyExpiry && <div className="p-3 bg-warm-50 rounded-lg"><p className="text-xs text-warm-500">Warranty Until</p><p className="font-medium">{system.warrantyExpiry}</p></div>}
                  {system.location && <div className="p-3 bg-warm-50 rounded-lg"><p className="text-xs text-warm-500">Location</p><p className="font-medium">{system.location}</p></div>}
                </div>
                {system.assignedVendor && (
                  <div className="flex items-center gap-4 p-4 bg-warm-50 rounded-xl">
                    <VendorAvatar name={system.assignedVendor.name} size="lg" />
                    <div className="flex-1">
                      <p className="font-semibold text-warm-900">{system.assignedVendor.name}</p>
                      <p className="text-sm text-warm-500">{system.assignedVendor.phone}</p>
                    </div>
                    <a href={`tel:${system.assignedVendor.phone}`} className="p-2 bg-haven-100 text-haven-700 rounded-lg"><Phone className="w-5 h-5" /></a>
                  </div>
                )}
                {system.notes && <div className="p-3 bg-amber-50 rounded-lg border border-amber-200"><p className="text-sm text-amber-700">{system.notes}</p></div>}
              </>
            )}
            {activeSection === 'history' && (
              <div className="space-y-3">
                {system.serviceHistory?.length ? system.serviceHistory.map(record => (
                  <div key={record.id} className="p-4 bg-white border border-warm-200 rounded-xl">
                    <div className="flex justify-between mb-2">
                      <p className="font-semibold">{record.date}</p>
                      {record.cost && <span className="font-semibold">${record.cost}</span>}
                    </div>
                    <p className="text-sm text-warm-600 mb-2">{record.description}</p>
                    <p className="text-xs text-warm-500">{record.vendor.name} {record.technicianName && `• ${record.technicianName}`}</p>
                  </div>
                )) : <p className="text-center py-8 text-warm-500">No service history</p>}
              </div>
            )}
            {activeSection === 'documents' && (
              <div className="space-y-3">
                {system.documents?.length ? system.documents.map(doc => (
                  <a key={doc.id} href={doc.url} className="flex items-center gap-4 p-4 bg-warm-50 rounded-xl hover:bg-warm-100">
                    <div className="w-10 h-10 rounded-lg bg-red-100 flex items-center justify-center"><FileText className="w-5 h-5 text-red-600" /></div>
                    <div className="flex-1"><p className="font-medium">{doc.name}</p><p className="text-xs text-warm-500">{doc.type} • {doc.uploadDate}</p></div>
                    <Download className="w-5 h-5 text-warm-400" />
                  </a>
                )) : <p className="text-center py-8 text-warm-500">No documents</p>}
              </div>
            )}
          </div>
          <div className="sticky bottom-0 bg-white border-t border-warm-200 p-4 flex gap-3">
            <button className="flex-1 py-3 border border-warm-200 text-warm-700 font-medium rounded-xl hover:bg-warm-50">Edit</button>
            <button className="flex-1 py-3 bg-haven-700 text-white font-medium rounded-xl hover:bg-haven-800">Schedule Service</button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function YourHomePage() {
  const [activeTab, setActiveTab] = useState<TabId>('overview');
  const [maintenanceFilter, setMaintenanceFilter] = useState<MaintenanceFilter>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [viewMode, setViewMode] = useState<ViewMode>('cards');
  const [selectedSystem, setSelectedSystem] = useState<HomeSystem | null>(null);
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set(['hvac', 'plumbing', 'Property', 'Financial', 'Insurance', 'Warranties', 'Manuals', 'Maintenance', 'Vehicles', 'Projects']));
  const [documentSearch, setDocumentSearch] = useState('');
  const [documentCategory, setDocumentCategory] = useState('all');

  // Maintenance stats
  const maintenanceStats = useMemo(() => {
    const systems = HOME_SYSTEMS.filter(s => s.maintenance);
    return {
      total: systems.length,
      overdue: systems.filter(s => s.maintenance?.status === 'overdue').length,
      dueSoon: systems.filter(s => s.maintenance?.status === 'due-soon').length,
      upcoming: systems.filter(s => s.maintenance?.status === 'upcoming').length,
      onTrack: systems.filter(s => s.maintenance?.status === 'on-track').length,
    };
  }, []);

  // Filtered systems
  const filteredSystems = useMemo(() => {
    let systems = HOME_SYSTEMS.filter(s => s.maintenance);
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      systems = systems.filter(s => s.name.toLowerCase().includes(q) || s.category.includes(q) || s.brand?.toLowerCase().includes(q));
    }
    if (maintenanceFilter !== 'all' && maintenanceFilter !== 'completed') {
      systems = systems.filter(s => s.maintenance?.status === maintenanceFilter);
    }
    return systems.sort((a, b) => (a.maintenance?.daysUntilDue ?? 999) - (b.maintenance?.daysUntilDue ?? 999));
  }, [searchQuery, maintenanceFilter]);

  // Systems by category
  const systemsByCategory = useMemo(() => {
    const grouped: Record<string, HomeSystem[]> = {};
    HOME_SYSTEMS.forEach(s => {
      if (!grouped[s.category]) grouped[s.category] = [];
      grouped[s.category].push(s);
    });
    return grouped;
  }, []);

  // Filtered documents
  const filteredDocuments = useMemo(() => {
    let docs = DOCUMENTS;
    if (documentCategory !== 'all') docs = docs.filter(d => d.category === documentCategory);
    if (documentSearch) {
      const q = documentSearch.toLowerCase();
      docs = docs.filter(d => d.name.toLowerCase().includes(q) || d.category.toLowerCase().includes(q));
    }
    return docs;
  }, [documentSearch, documentCategory]);

  const documentCategories = useMemo(() => ['all', ...new Set(DOCUMENTS.map(d => d.category))], []);

  const toggleCategory = (cat: string) => {
    setExpandedCategories(prev => {
      const next = new Set(prev);
      next.has(cat) ? next.delete(cat) : next.add(cat);
      return next;
    });
  };

  // Financial totals
  const totalMonthlyDebt = LOANS.reduce((sum, l) => sum + l.monthlyPayment, 0);
  const totalDebtBalance = LOANS.reduce((sum, l) => sum + l.currentBalance, 0);
  const totalAnnualInsurance = INSURANCE_POLICIES.reduce((sum, p) => {
    const mult = p.premiumFrequency === 'annual' ? 1 : p.premiumFrequency === 'semi-annual' ? 2 : p.premiumFrequency === 'quarterly' ? 4 : 12;
    return sum + p.premium * mult;
  }, 0);

  // ============================================================================
  // RENDER VEHICLES TAB
  // ============================================================================
  const renderVehicles = () => (
    <div className="space-y-6">
      {VEHICLES.map(vehicle => {
        const loan = LOANS.find(l => l.vehicleId === vehicle.id);
        return (
          <div key={vehicle.id} className="bg-white rounded-2xl border border-warm-200 overflow-hidden">
            <div className="flex flex-col sm:flex-row">
              {vehicle.photoUrl && (
                <div className="sm:w-64 h-48 sm:h-auto overflow-hidden flex-shrink-0">
                  <img src={vehicle.photoUrl} alt={vehicle.nickname} className="w-full h-full object-cover" />
                </div>
              )}
              <div className="flex-1 p-4 sm:p-6">
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="text-xl font-bold text-warm-900">{vehicle.nickname}</h3>
                    <p className="text-warm-600">{vehicle.year} {vehicle.make} {vehicle.model} {vehicle.trim}</p>
                    <p className="text-sm text-warm-500">{vehicle.color}</p>
                  </div>
                  <span className={`px-3 py-1 text-sm font-medium rounded-full ${vehicle.ownership === 'owned' ? 'bg-green-100 text-green-700' : vehicle.ownership === 'financed' ? 'bg-blue-100 text-blue-700' : 'bg-purple-100 text-purple-700'}`}>
                    {vehicle.ownership.charAt(0).toUpperCase() + vehicle.ownership.slice(1)}
                  </span>
                </div>
                {/* Quick Stats Row */}
                <div className="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-3">
                  <div className="p-3 bg-warm-50 rounded-lg">
                    <div className="flex items-center gap-2 text-warm-500 text-xs mb-1"><Gauge className="w-3.5 h-3.5" />Mileage</div>
                    <p className="font-bold text-warm-900">{vehicle.mileage.toLocaleString()} mi</p>
                  </div>
                  <div className="p-3 bg-warm-50 rounded-lg">
                    <div className="flex items-center gap-2 text-warm-500 text-xs mb-1"><CarFront className="w-3.5 h-3.5" />License</div>
                    <p className="font-mono font-bold text-warm-900">{vehicle.licensePlate} <span className="text-warm-500 text-xs font-normal">{vehicle.state}</span></p>
                  </div>
                  <div className="p-3 bg-warm-50 rounded-lg">
                    <div className="flex items-center gap-2 text-warm-500 text-xs mb-1"><Zap className="w-3.5 h-3.5" />Fuel Type</div>
                    <p className="font-bold text-warm-900">{vehicle.fuelType}</p>
                  </div>
                  <div className="p-3 bg-warm-50 rounded-lg">
                    <div className="flex items-center gap-2 text-warm-500 text-xs mb-1"><Key className="w-3.5 h-3.5" />VIN</div>
                    <p className="font-mono text-xs font-bold text-warm-900 truncate">{vehicle.vin}</p>
                  </div>
                </div>
                {/* Registration & Inspection Row */}
                <div className="mt-3 grid grid-cols-2 gap-3">
                  <div className={`p-3 rounded-lg ${new Date(vehicle.registrationExpiry) < new Date() ? 'bg-red-50 border border-red-200' : 'bg-warm-50'}`}>
                    <div className="flex items-center gap-2 text-warm-500 text-xs mb-1"><FileCheck className="w-3.5 h-3.5" />Registration</div>
                    <p className={`font-bold ${new Date(vehicle.registrationExpiry) < new Date() ? 'text-red-700' : 'text-warm-900'}`}>{vehicle.registrationExpiry}</p>
                    {vehicle.registrationCost && <p className="text-xs text-warm-500 mt-0.5">{formatCurrency(vehicle.registrationCost)}/year</p>}
                  </div>
                  {vehicle.inspectionExpiry ? (
                    <div className={`p-3 rounded-lg ${new Date(vehicle.inspectionExpiry) < new Date() ? 'bg-red-50 border border-red-200' : 'bg-warm-50'}`}>
                      <div className="flex items-center gap-2 text-warm-500 text-xs mb-1"><BadgeCheck className="w-3.5 h-3.5" />Inspection</div>
                      <p className={`font-bold ${new Date(vehicle.inspectionExpiry) < new Date() ? 'text-red-700' : 'text-warm-900'}`}>{vehicle.inspectionExpiry}</p>
                      {vehicle.inspectionType && <p className="text-xs text-warm-500 mt-0.5">{vehicle.inspectionType}</p>}
                    </div>
                  ) : vehicle.inspectionType && (
                    <div className="p-3 bg-green-50 rounded-lg">
                      <div className="flex items-center gap-2 text-warm-500 text-xs mb-1"><BadgeCheck className="w-3.5 h-3.5" />Inspection</div>
                      <p className="font-bold text-green-700">{vehicle.inspectionType}</p>
                    </div>
                  )}
                </div>
              </div>
            </div>
            <div className="border-t border-warm-200">
              <div className="grid grid-cols-1 md:grid-cols-3 divide-y md:divide-y-0 md:divide-x divide-warm-200">
                {/* Insurance */}
                <div className="p-4">
                  <h4 className="font-semibold text-warm-900 mb-3 flex items-center gap-2"><Shield className="w-4 h-4 text-blue-600" />Insurance</h4>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between"><span className="text-warm-500">Provider</span><span className="font-medium">{vehicle.insuranceProvider}</span></div>
                    <div className="flex justify-between"><span className="text-warm-500">Policy #</span><span className="font-mono text-warm-700">{vehicle.insurancePolicy}</span></div>
                    <div className="flex justify-between"><span className="text-warm-500">Premium</span><span className="font-medium">{formatCurrency(vehicle.insurancePremium)}/{vehicle.insuranceFrequency}</span></div>
                    <div className="flex justify-between"><span className="text-warm-500">Expires</span><span className="font-medium">{vehicle.insuranceExpiry}</span></div>
                    {vehicle.insuranceDeductible && <div className="flex justify-between"><span className="text-warm-500">Deductible</span><span className="font-medium">{formatCurrency(vehicle.insuranceDeductible)}</span></div>}
                  </div>
                </div>
                {/* Service */}
                <div className="p-4">
                  <h4 className="font-semibold text-warm-900 mb-3 flex items-center gap-2"><Wrench className="w-4 h-4 text-orange-600" />Service</h4>
                  <div className="space-y-2 text-sm">
                    {vehicle.primaryServiceProvider && (
                      <div>
                        <p className="text-warm-500 text-xs">Service Provider</p>
                        <p className="font-medium">{vehicle.primaryServiceProvider.name}</p>
                        <p className="text-warm-500">{vehicle.primaryServiceProvider.phone}</p>
                        {vehicle.primaryServiceProvider.address && <p className="text-warm-400 text-xs mt-0.5">{vehicle.primaryServiceProvider.address}</p>}
                      </div>
                    )}
                    {vehicle.oilChangeInterval && <div className="flex justify-between mt-2"><span className="text-warm-500">Oil Interval</span><span className="font-medium">{vehicle.oilChangeInterval}</span></div>}
                    {vehicle.lastOilChange && <div className="flex justify-between"><span className="text-warm-500">Last Oil Change</span><span className="font-medium">{vehicle.lastOilChange}</span></div>}
                    {vehicle.nextOilChange && <div className="flex justify-between"><span className="text-warm-500">Next Oil Change</span><span className="font-medium text-haven-700">{vehicle.nextOilChange}</span></div>}
                  </div>
                </div>
                {/* Loan/Lease */}
                <div className="p-4">
                  <h4 className="font-semibold text-warm-900 mb-3 flex items-center gap-2"><Banknote className="w-4 h-4 text-green-600" />{vehicle.ownership === 'leased' ? 'Lease' : 'Loan'}</h4>
                  {vehicle.hasLoan && loan ? (
                    <div className="space-y-2 text-sm">
                      <div className="flex justify-between"><span className="text-warm-500">Lender</span><span className="font-medium">{loan.lender}</span></div>
                      <div className="flex justify-between"><span className="text-warm-500">Payment</span><span className="font-medium">{formatCurrency(loan.monthlyPayment)}/mo</span></div>
                      <div className="flex justify-between"><span className="text-warm-500">Balance</span><span className="font-medium">{formatCurrency(loan.currentBalance)}</span></div>
                      <div className="flex justify-between"><span className="text-warm-500">Rate</span><span className="font-medium">{loan.interestRate}% {loan.interestType}</span></div>
                      <div className="flex justify-between"><span className="text-warm-500">Maturity</span><span className="text-warm-700">{loan.maturityDate}</span></div>
                      <div className="flex justify-between"><span className="text-warm-500">Remaining</span><span className="text-warm-700">{loan.remainingPayments} payments</span></div>
                      <div className="mt-2">
                        <div className="h-2 bg-warm-100 rounded-full overflow-hidden"><div className="h-full bg-green-500 rounded-full" style={{ width: `${loan.percentPaid}%` }} /></div>
                        <p className="text-xs text-warm-500 mt-1">{loan.percentPaid}% paid</p>
                      </div>
                    </div>
                  ) : (
                    <div className="flex items-center justify-center h-24 text-green-600"><CheckCircle2 className="w-5 h-5 mr-2" /><span className="font-medium">Paid Off / Owned</span></div>
                  )}
                </div>
              </div>
            </div>
            {/* Service History */}
            {vehicle.serviceHistory.length > 0 && (
              <div className="border-t border-warm-200 p-4">
                <h4 className="font-semibold text-warm-900 mb-3 flex items-center gap-2"><History className="w-4 h-4 text-warm-400" />Service History ({vehicle.serviceHistory.length})</h4>
                <div className="space-y-2">
                  {vehicle.serviceHistory.slice(0, 5).map(record => {
                    const typeBadge = {
                      scheduled: { bg: 'bg-blue-100', text: 'text-blue-700', label: 'Scheduled' },
                      repair: { bg: 'bg-red-100', text: 'text-red-700', label: 'Repair' },
                      'oil-change': { bg: 'bg-amber-100', text: 'text-amber-700', label: 'Oil Change' },
                      tire: { bg: 'bg-purple-100', text: 'text-purple-700', label: 'Tires' },
                      brake: { bg: 'bg-orange-100', text: 'text-orange-700', label: 'Brakes' },
                      inspection: { bg: 'bg-green-100', text: 'text-green-700', label: 'Inspection' },
                      installation: { bg: 'bg-cyan-100', text: 'text-cyan-700', label: 'Install' },
                      replacement: { bg: 'bg-pink-100', text: 'text-pink-700', label: 'Replace' },
                    }[record.type] || { bg: 'bg-warm-100', text: 'text-warm-700', label: record.type };
                    return (
                      <div key={record.id} className="flex items-center justify-between p-3 bg-warm-50 rounded-lg">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                            <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${typeBadge.bg} ${typeBadge.text}`}>{typeBadge.label}</span>
                          </div>
                          <p className="font-medium text-warm-900 text-sm">{record.description}</p>
                          <p className="text-xs text-warm-500">{record.date} • {record.vendor.name} {record.mileage && `• ${record.mileage.toLocaleString()} mi`}</p>
                        </div>
                        {record.cost !== undefined && <span className={`font-medium text-sm ${record.cost === 0 ? 'text-green-600' : 'text-warm-700'}`}>{record.cost === 0 ? 'Included' : formatCurrency(record.cost)}</span>}
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
            {/* Documents */}
            {vehicle.documents.length > 0 && (
              <div className="border-t border-warm-200 p-4">
                <h4 className="font-semibold text-warm-900 mb-3 flex items-center gap-2"><FileText className="w-4 h-4 text-warm-400" />Documents ({vehicle.documents.length})</h4>
                <div className="flex flex-wrap gap-2">
                  {vehicle.documents.map(doc => (
                    <a key={doc.id} href={doc.url} className="inline-flex items-center gap-2 px-3 py-2 bg-warm-50 hover:bg-warm-100 rounded-lg text-sm">
                      <FileText className="w-4 h-4 text-red-500" /><span className="text-warm-700">{doc.name}</span>
                    </a>
                  ))}
                </div>
              </div>
            )}
            {/* Notes */}
            {vehicle.notes && (
              <div className="border-t border-warm-200 p-4 bg-amber-50">
                <p className="text-sm text-amber-800 flex items-start gap-2"><Info className="w-4 h-4 flex-shrink-0 mt-0.5" />{vehicle.notes}</p>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );

  // ============================================================================
  // RENDER FINANCIAL TAB
  // ============================================================================
  const renderFinancial = () => (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-warm-200 p-4">
          <p className="text-sm text-warm-500 mb-1">Monthly Payments</p>
          <p className="text-2xl font-bold text-warm-900">{formatCurrency(totalMonthlyDebt)}</p>
        </div>
        <div className="bg-white rounded-xl border border-warm-200 p-4">
          <p className="text-sm text-warm-500 mb-1">Total Debt</p>
          <p className="text-2xl font-bold text-warm-900">{formatCurrency(totalDebtBalance)}</p>
        </div>
        <div className="bg-white rounded-xl border border-warm-200 p-4">
          <p className="text-sm text-warm-500 mb-1">Annual Insurance</p>
          <p className="text-2xl font-bold text-warm-900">{formatCurrency(totalAnnualInsurance)}</p>
        </div>
        <div className="bg-white rounded-xl border border-warm-200 p-4">
          <p className="text-sm text-warm-500 mb-1">Property Taxes</p>
          <p className="text-2xl font-bold text-warm-900">{formatCurrency(PROPERTY_TAX.annualAmount)}/yr</p>
        </div>
      </div>

      {/* Loans */}
      <div>
        <h3 className="text-lg font-bold text-warm-900 mb-4 flex items-center gap-2"><Landmark className="w-5 h-5 text-warm-400" />Loans & Mortgages</h3>
        <div className="space-y-4">
          {LOANS.map(loan => (
            <div key={loan.id} className="bg-white rounded-xl border border-warm-200 overflow-hidden">
              <div className="p-4 sm:p-6">
                <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${loan.type === 'mortgage' ? 'bg-blue-100 text-blue-700' : loan.type === 'heloc' ? 'bg-purple-100 text-purple-700' : loan.type === 'auto' ? 'bg-green-100 text-green-700' : loan.type === 'student' ? 'bg-amber-100 text-amber-700' : 'bg-warm-100 text-warm-700'}`}>
                        {loan.type.toUpperCase()} {loan.subtype && `• ${loan.subtype}`}
                      </span>
                    </div>
                    <h4 className="text-lg font-bold text-warm-900">{loan.nickname}</h4>
                    <p className="text-warm-500">{loan.lender} • {loan.accountNumber}</p>
                  </div>
                  <div className="text-left sm:text-right">
                    <p className="text-2xl font-bold text-warm-900">{formatCurrency(loan.currentBalance)}</p>
                    <p className="text-sm text-warm-500">of {formatCurrency(loan.originalAmount)} original</p>
                  </div>
                </div>
                <div className="mt-4">
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-warm-500">Paid: {formatCurrency(loan.paidAmount)}</span>
                    <span className="font-medium text-haven-700">{loan.percentPaid}%</span>
                  </div>
                  <div className="h-3 bg-warm-100 rounded-full overflow-hidden">
                    <div className="h-full bg-haven-700 rounded-full" style={{ width: `${loan.percentPaid}%` }} />
                  </div>
                </div>
                <div className="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-4">
                  <div><p className="text-xs text-warm-500">Interest Rate</p><p className="font-semibold">{loan.interestRate}% <span className="text-xs font-normal text-warm-500">{loan.interestType}</span></p></div>
                  <div><p className="text-xs text-warm-500">Monthly Payment</p><p className="font-semibold">{formatCurrency(loan.monthlyPayment)}</p></div>
                  <div><p className="text-xs text-warm-500">Next Payment</p><p className="font-semibold">{loan.nextPaymentDate}</p></div>
                  <div><p className="text-xs text-warm-500">Remaining</p><p className="font-semibold">{loan.remainingPayments} payments</p></div>
                </div>
                {loan.includesEscrow && (
                  <div className="mt-4 p-3 bg-blue-50 rounded-lg">
                    <p className="text-xs font-medium text-blue-700 mb-2">Monthly Payment Breakdown</p>
                    <div className="grid grid-cols-3 gap-2 text-sm">
                      <div><p className="text-blue-600 text-xs">Principal & Interest</p><p className="font-medium text-blue-900">{formatCurrency(loan.monthlyPayment - (loan.escrowAmount || 0))}</p></div>
                      <div><p className="text-blue-600 text-xs">Property Tax</p><p className="font-medium text-blue-900">{formatCurrency((loan.propertyTaxAmount || 0) / 12)}</p></div>
                      <div><p className="text-blue-600 text-xs">Insurance</p><p className="font-medium text-blue-900">{formatCurrency((loan.homeownersInsuranceAmount || 0) / 12)}</p></div>
                    </div>
                  </div>
                )}
                <div className="mt-4 flex items-center gap-4 text-sm">
                  {loan.autopayEnabled && <span className="flex items-center gap-1 text-green-600"><CheckCircle2 className="w-4 h-4" />Autopay enabled</span>}
                  {loan.paymentMethod && <span className="text-warm-500">{loan.paymentMethod}</span>}
                </div>
              </div>
              {(loan.lenderPhone || loan.lenderWebsite) && (
                <div className="border-t border-warm-200 px-4 py-3 bg-warm-50 flex items-center gap-4 text-sm">
                  {loan.lenderPhone && <a href={`tel:${loan.lenderPhone}`} className="flex items-center gap-1 text-haven-700"><Phone className="w-4 h-4" />{loan.lenderPhone}</a>}
                  {loan.lenderWebsite && <a href={`https://${loan.lenderWebsite}`} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-haven-700"><Globe className="w-4 h-4" />{loan.lenderWebsite}</a>}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Insurance */}
      <div>
        <h3 className="text-lg font-bold text-warm-900 mb-4 flex items-center gap-2"><Shield className="w-5 h-5 text-warm-400" />Insurance Policies</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {INSURANCE_POLICIES.map(policy => (
            <div key={policy.id} className="bg-white rounded-xl border border-warm-200 overflow-hidden">
              <div className="p-4">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${policy.type === 'homeowners' ? 'bg-blue-100' : policy.type === 'auto' ? 'bg-green-100' : policy.type === 'umbrella' ? 'bg-purple-100' : policy.type === 'life' ? 'bg-pink-100' : 'bg-warm-100'}`}>
                      {policy.type === 'homeowners' ? <Home className="w-5 h-5 text-blue-600" /> : policy.type === 'auto' ? <Car className="w-5 h-5 text-green-600" /> : policy.type === 'umbrella' ? <Shield className="w-5 h-5 text-purple-600" /> : policy.type === 'life' ? <Heart className="w-5 h-5 text-pink-600" /> : <Shield className="w-5 h-5 text-warm-600" />}
                    </div>
                    <div>
                      <h4 className="font-semibold text-warm-900 capitalize">{policy.type} Insurance</h4>
                      <p className="text-sm text-warm-500">{policy.provider}</p>
                    </div>
                  </div>
                  {policy.autoRenew && <span className="px-2 py-1 bg-green-100 text-green-700 text-xs font-medium rounded-full flex items-center gap-1"><RefreshCw className="w-3 h-3" />Auto-renew</span>}
                </div>
                <div className="grid grid-cols-2 gap-3 text-sm">
                  <div><p className="text-warm-500 text-xs">Policy #</p><p className="font-mono text-warm-700">{policy.policyNumber}</p></div>
                  <div><p className="text-warm-500 text-xs">Premium</p><p className="font-semibold">{formatCurrency(policy.premium)}/{policy.premiumFrequency}</p></div>
                  {policy.coverage && <div><p className="text-warm-500 text-xs">Coverage</p><p className="font-semibold">{formatCurrency(policy.coverage)}</p></div>}
                  {policy.deductible && <div><p className="text-warm-500 text-xs">Deductible</p><p className="font-semibold">{formatCurrency(policy.deductible)}</p></div>}
                  <div className="col-span-2"><p className="text-warm-500 text-xs">Coverage Period</p><p className="font-medium">{policy.effectiveDate} - {policy.expiryDate}</p></div>
                </div>
                {policy.coverageDetails && (
                  <div className="mt-3 pt-3 border-t border-warm-100">
                    <p className="text-xs text-warm-500 mb-2">Coverage Details</p>
                    <div className="space-y-1">
                      {policy.coverageDetails.slice(0, 4).map((detail, idx) => (
                        <p key={idx} className="text-sm text-warm-600 flex items-center gap-2"><CheckCircle2 className="w-3.5 h-3.5 text-green-500 flex-shrink-0" />{detail}</p>
                      ))}
                    </div>
                  </div>
                )}
                {policy.coveredItems && (
                  <div className="mt-3 pt-3 border-t border-warm-100">
                    <p className="text-xs text-warm-500 mb-2">Covered Items</p>
                    <div className="flex flex-wrap gap-1">
                      {policy.coveredItems.map((item, idx) => <span key={idx} className="px-2 py-1 bg-warm-100 text-warm-600 text-xs rounded-full">{item}</span>)}
                    </div>
                  </div>
                )}
              </div>
              {policy.agentName && (
                <div className="border-t border-warm-200 px-4 py-3 bg-warm-50">
                  <p className="text-xs text-warm-500 mb-1">Agent</p>
                  <p className="font-medium text-warm-900">{policy.agentName}</p>
                  <div className="flex items-center gap-3 mt-1 text-sm">
                    {policy.agentPhone && <a href={`tel:${policy.agentPhone}`} className="text-haven-700">{policy.agentPhone}</a>}
                    {policy.agentEmail && <a href={`mailto:${policy.agentEmail}`} className="text-haven-700">{policy.agentEmail}</a>}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Property Tax */}
      <div>
        <h3 className="text-lg font-bold text-warm-900 mb-4 flex items-center gap-2"><Receipt className="w-5 h-5 text-warm-400" />Property Tax</h3>
        <div className="bg-white rounded-xl border border-warm-200 p-4 sm:p-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
            <div><p className="text-warm-500 text-xs">Annual Amount</p><p className="text-xl font-bold text-warm-900">{formatCurrency(PROPERTY_TAX.annualAmount)}</p></div>
            <div><p className="text-warm-500 text-xs">Assessed Value</p><p className="text-xl font-bold text-warm-900">{formatCurrency(PROPERTY_TAX.assessedValue)}</p></div>
            <div><p className="text-warm-500 text-xs">Mill Rate</p><p className="text-xl font-bold text-warm-900">{PROPERTY_TAX.taxRate}</p></div>
            <div><p className="text-warm-500 text-xs">Next Payment</p><p className="text-xl font-bold text-haven-700">{PROPERTY_TAX.nextPaymentDate}</p><p className="text-sm text-warm-500">{formatCurrency(PROPERTY_TAX.nextPaymentAmount)}</p></div>
          </div>
          {PROPERTY_TAX.paidThroughEscrow && <div className="flex items-center gap-2 text-sm text-green-600 mb-4"><CheckCircle2 className="w-4 h-4" />Paid through mortgage escrow</div>}
          <div className="border-t border-warm-200 pt-4">
            <p className="text-sm font-medium text-warm-700 mb-2">Payment History</p>
            <div className="space-y-2">
              {PROPERTY_TAX.paymentHistory.map((payment, idx) => (
                <div key={idx} className="flex items-center justify-between p-2 bg-warm-50 rounded-lg text-sm">
                  <span className="text-warm-600">{payment.period}</span>
                  <span className="text-warm-500">{payment.date}</span>
                  <span className="font-medium text-warm-900">{formatCurrency(payment.amount)}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Property Value */}
      <div className="bg-gradient-to-br from-haven-700 to-haven-800 rounded-2xl p-6 text-white">
        <h3 className="font-semibold flex items-center gap-2 mb-4"><TrendingUp className="w-5 h-5" />Property Value</h3>
        <div className="grid grid-cols-2 gap-6">
          <div>
            <p className="text-haven-200 text-sm">Purchase Price</p>
            <p className="text-3xl font-bold">{formatCurrency(PROPERTY.purchasePrice)}</p>
            <p className="text-haven-200 text-xs">{PROPERTY.purchaseDate}</p>
          </div>
          <div>
            <p className="text-haven-200 text-sm">Current Estimate</p>
            <p className="text-3xl font-bold">{formatCurrency(PROPERTY.currentValue)}</p>
            <p className="text-green-300 text-sm font-medium flex items-center gap-1 mt-1">
              <TrendingUp className="w-4 h-4" />+{formatCurrency(PROPERTY.currentValue - PROPERTY.purchasePrice)} ({(((PROPERTY.currentValue - PROPERTY.purchasePrice) / PROPERTY.purchasePrice) * 100).toFixed(1)}%)
            </p>
          </div>
        </div>
        <div className="mt-4 pt-4 border-t border-haven-600 grid grid-cols-3 gap-4 text-sm">
          <div><p className="text-haven-200">Equity</p><p className="font-bold">{formatCurrency(PROPERTY.currentValue - (LOANS.find(l => l.type === 'mortgage')?.currentBalance || 0))}</p></div>
          <div><p className="text-haven-200">Mortgage Balance</p><p className="font-bold">{formatCurrency(LOANS.find(l => l.type === 'mortgage')?.currentBalance || 0)}</p></div>
          <div><p className="text-haven-200">LTV Ratio</p><p className="font-bold">{(((LOANS.find(l => l.type === 'mortgage')?.currentBalance || 0) / PROPERTY.currentValue) * 100).toFixed(1)}%</p></div>
        </div>
      </div>
    </div>
  );

  // ============================================================================
  // RENDER DOCUMENTS TAB
  // ============================================================================
  const getFileTypeIcon = (fileType: string) => {
    switch (fileType) {
      case 'pdf':
        return { bg: 'bg-red-100', icon: FileText, color: 'text-red-600' };
      case 'image':
        return { bg: 'bg-blue-100', icon: FileImage, color: 'text-blue-600' };
      case 'spreadsheet':
      case 'xlsx':
      case 'csv':
        return { bg: 'bg-green-100', icon: FileText, color: 'text-green-600' };
      default:
        return { bg: 'bg-warm-100', icon: FileText, color: 'text-warm-600' };
    }
  };

  const renderDocuments = () => {
    const groupedDocs: Record<string, Document[]> = {};
    filteredDocuments.forEach(doc => {
      if (!groupedDocs[doc.category]) groupedDocs[doc.category] = [];
      groupedDocs[doc.category].push(doc);
    });

    return (
      <div className="space-y-6">
        {/* Search & Filter */}
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-warm-400" />
            <input
              type="text"
              value={documentSearch}
              onChange={(e) => setDocumentSearch(e.target.value)}
              placeholder="Search documents..."
              className="w-full pl-10 pr-4 py-2.5 border border-warm-200 rounded-xl focus:ring-2 focus:ring-haven-600 focus:border-haven-700"
            />
          </div>
          <select
            value={documentCategory}
            onChange={(e) => setDocumentCategory(e.target.value)}
            className="px-4 py-2.5 border border-warm-200 rounded-xl bg-white"
          >
            {documentCategories.map(cat => <option key={cat} value={cat}>{cat === 'all' ? 'All Categories' : cat}</option>)}
          </select>
          <button className="px-4 py-2.5 bg-haven-700 text-white font-medium rounded-xl hover:bg-haven-800 flex items-center gap-2">
            <Upload className="w-5 h-5" />Upload
          </button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div className="bg-white rounded-xl border border-warm-200 p-3"><p className="text-2xl font-bold text-warm-900">{DOCUMENTS.length}</p><p className="text-sm text-warm-500">Total Documents</p></div>
          <div className="bg-white rounded-xl border border-warm-200 p-3"><p className="text-2xl font-bold text-warm-900">{documentCategories.length - 1}</p><p className="text-sm text-warm-500">Categories</p></div>
          <div className="bg-white rounded-xl border border-warm-200 p-3"><p className="text-2xl font-bold text-amber-600">{DOCUMENTS.filter(d => d.expiryDate).length}</p><p className="text-sm text-warm-500">Expiring Docs</p></div>
          <div className="bg-white rounded-xl border border-warm-200 p-3"><p className="text-2xl font-bold text-haven-700">{DOCUMENTS.filter(d => d.isFavorite).length}</p><p className="text-sm text-warm-500">Favorites</p></div>
        </div>

        {/* Favorites */}
        {DOCUMENTS.filter(d => d.isFavorite).length > 0 && documentCategory === 'all' && !documentSearch && (
          <div className="bg-amber-50 rounded-xl border border-amber-200 p-4">
            <h3 className="font-semibold text-amber-900 mb-3 flex items-center gap-2"><Star className="w-5 h-5 text-amber-500 fill-current" />Quick Access</h3>
            <div className="flex flex-wrap gap-2">
              {DOCUMENTS.filter(d => d.isFavorite).map(doc => {
                const ft = getFileTypeIcon(doc.fileType);
                const FileIcon = ft.icon;
                return (
                  <a key={doc.id} href={doc.url} className="flex items-center gap-2 px-3 py-2 bg-white hover:bg-amber-100 rounded-lg text-sm border border-amber-200">
                    <FileIcon className={`w-4 h-4 ${ft.color}`} /><span className="text-warm-700">{doc.name}</span><Download className="w-4 h-4 text-warm-400" />
                  </a>
                );
              })}
            </div>
          </div>
        )}

        {/* Documents by Category */}
        {Object.entries(groupedDocs).map(([category, docs]) => (
          <div key={category} className="bg-white rounded-xl border border-warm-200 overflow-hidden">
            <button
              onClick={() => toggleCategory(category)}
              className="w-full p-4 border-b border-warm-100 bg-warm-50 flex items-center justify-between hover:bg-warm-100 transition-colors"
            >
              <h3 className="font-semibold text-warm-900 flex items-center gap-2"><FolderOpen className="w-5 h-5 text-warm-400" />{category}</h3>
              <div className="flex items-center gap-2">
                <span className="text-sm text-warm-500">{docs.length} files</span>
                {expandedCategories.has(category) ? <ChevronUp className="w-5 h-5 text-warm-400" /> : <ChevronDown className="w-5 h-5 text-warm-400" />}
              </div>
            </button>
            {expandedCategories.has(category) && (
              <div className="divide-y divide-warm-100">
                {docs.map(doc => {
                  const ft = getFileTypeIcon(doc.fileType);
                  const FileIcon = ft.icon;
                  return (
                    <div key={doc.id} className="p-4 flex items-center gap-4 hover:bg-warm-50 group">
                      <div className={`w-10 h-10 rounded-lg ${ft.bg} flex items-center justify-center`}><FileIcon className={`w-5 h-5 ${ft.color}`} /></div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <p className="font-medium text-warm-900 truncate">{doc.name}</p>
                          {doc.isFavorite && <Star className="w-4 h-4 text-amber-500 fill-current flex-shrink-0" />}
                          {doc.expiryDate && <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs rounded-full flex-shrink-0">Exp: {doc.expiryDate}</span>}
                        </div>
                        <div className="flex items-center gap-2 text-sm text-warm-500">
                          <span className="uppercase text-xs font-medium">{doc.fileType}</span><span>•</span>
                          <span>{doc.fileSize}</span><span>•</span><span>{doc.uploadDate}</span>
                          {doc.subcategory && <><span>•</span><span>{doc.subcategory}</span></>}
                          {doc.linkedTo && <><span>•</span><span className="text-haven-700">{doc.linkedTo.name}</span></>}
                        </div>
                      </div>
                      <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <a href={doc.url} className="p-2 text-haven-700 hover:bg-haven-50 rounded-lg"><Eye className="w-5 h-5" /></a>
                        <a href={doc.url} download className="p-2 text-haven-700 hover:bg-haven-50 rounded-lg"><Download className="w-5 h-5" /></a>
                        <button className="p-2 text-warm-400 hover:bg-warm-100 rounded-lg"><MoreVertical className="w-5 h-5" /></button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        ))}

        {filteredDocuments.length === 0 && (
          <div className="text-center py-12">
            <FileText className="w-12 h-12 text-warm-300 mx-auto mb-3" />
            <p className="text-warm-500">No documents found</p>
            <p className="text-sm text-warm-400">Try adjusting your search or filters</p>
          </div>
        )}
      </div>
    );
  };

  // ============================================================================
  // RENDER MAINTENANCE TAB
  // ============================================================================
  const renderMaintenance = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
        {[
          { id: 'all', label: 'Total', count: maintenanceStats.total, color: '' },
          { id: 'overdue', label: 'Overdue', count: maintenanceStats.overdue, color: 'text-red-600' },
          { id: 'due-soon', label: 'Due Soon', count: maintenanceStats.dueSoon, color: 'text-amber-600' },
          { id: 'upcoming', label: 'Upcoming', count: maintenanceStats.upcoming, color: 'text-blue-600' },
          { id: 'completed', label: 'On Track', count: maintenanceStats.onTrack, color: 'text-green-600' },
        ].map(filter => (
          <button
            key={filter.id}
            onClick={() => setMaintenanceFilter(filter.id as any)}
            className={`p-4 rounded-xl border transition-colors ${maintenanceFilter === filter.id ? 'bg-haven-50 border-haven-300' : 'bg-white border-warm-200'}`}
          >
            <p className={`text-2xl font-bold ${filter.color || 'text-warm-900'}`}>{filter.count}</p>
            <p className={`text-xs ${filter.color || 'text-warm-500'}`}>{filter.label}</p>
          </button>
        ))}
      </div>
      <div className="flex gap-3">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-warm-400" />
          <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search systems..." className="w-full pl-10 pr-4 py-2.5 border border-warm-200 rounded-xl" />
        </div>
        <div className="flex gap-2">
          <button onClick={() => setViewMode('cards')} className={`p-2.5 rounded-lg border ${viewMode === 'cards' ? 'bg-haven-100 border-haven-300' : 'border-warm-200'}`}><LayoutGrid className="w-5 h-5" /></button>
          <button onClick={() => setViewMode('list')} className={`p-2.5 rounded-lg border ${viewMode === 'list' ? 'bg-haven-100 border-haven-300' : 'border-warm-200'}`}><List className="w-5 h-5" /></button>
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredSystems.map(system => {
          const status = getStatusConfig(system.maintenance?.status || 'on-track');
          const category = getCategoryColor(system.category);
          const CategoryIcon = getCategoryIcon(system.category);
          const StatusIcon = status.icon;
          const currentYear = new Date().getFullYear();
          const ageYears = system.installYear ? currentYear - system.installYear : 0;
          const lifespanPercent = system.expectedLifespan ? Math.min(100, (ageYears / system.expectedLifespan) * 100) : 0;
          return (
            <div key={system.id} onClick={() => setSelectedSystem(system)} className={`bg-white rounded-xl border-2 overflow-hidden cursor-pointer hover:shadow-md ${status.border}`}>
              <div className={`px-4 py-2 ${status.bg} flex items-center justify-between`}>
                <div className="flex items-center gap-2"><StatusIcon className={`w-4 h-4 ${status.text}`} /><span className={`text-sm font-medium ${status.text}`}>{status.label}</span></div>
                <span className={`text-xs font-medium ${status.text}`}>{formatDaysUntilDue(system.maintenance?.daysUntilDue || 0)}</span>
              </div>
              <div className="p-4">
                <div className="flex items-start gap-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${category.bg}`}><CategoryIcon className={`w-5 h-5 ${category.text}`} /></div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-warm-900 truncate">{system.name}</h3>
                    <p className="text-sm text-warm-500">{system.brand && system.model ? `${system.brand} ${system.model}` : getCategoryLabel(system.category)}</p>
                  </div>
                </div>
                {system.installYear && system.expectedLifespan && (
                  <div className="mt-4">
                    <div className="flex items-center justify-between text-xs text-warm-500 mb-1">
                      <span>Lifespan</span>
                      <span>Year {ageYears} of {system.expectedLifespan}</span>
                    </div>
                    <div className="w-full bg-warm-100 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full transition-all ${
                          lifespanPercent > 80 ? 'bg-red-500' : lifespanPercent > 60 ? 'bg-amber-500' : 'bg-green-500'
                        }`}
                        style={{ width: `${lifespanPercent}%` }}
                      />
                    </div>
                  </div>
                )}
                <div className="mt-4 space-y-2 text-sm">
                  <div className="flex justify-between"><span className="text-warm-500">Last Service</span><span className="font-medium">{system.maintenance?.lastService}</span></div>
                  <div className="flex justify-between"><span className="text-warm-500">Next Service</span><span className={`font-medium ${status.text}`}>{system.maintenance?.nextService}</span></div>
                </div>
                {system.assignedVendor && (
                  <div className="mt-4 pt-3 border-t border-warm-100 flex items-center gap-2">
                    <VendorAvatar name={system.assignedVendor.name} size="sm" />
                    <p className="text-sm text-warm-700 truncate">{system.assignedVendor.name}</p>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );

  // ============================================================================
  // RENDER OTHER TABS
  // ============================================================================
  // Calculate home health score (0-100 based on maintenance status)
  const homeHealthScore = useMemo(() => {
    const total = maintenanceStats.overdue + maintenanceStats.dueSoon + maintenanceStats.upcoming + maintenanceStats.onTrack;
    if (total === 0) return 100;
    const overdueWeight = maintenanceStats.overdue * 0;
    const dueSoonWeight = maintenanceStats.dueSoon * 50;
    const upcomingWeight = maintenanceStats.upcoming * 80;
    const onTrackWeight = maintenanceStats.onTrack * 100;
    return Math.round((overdueWeight + dueSoonWeight + upcomingWeight + onTrackWeight) / total);
  }, [maintenanceStats]);

  // Mock upcoming maintenance data
  const upcomingMaintenance = useMemo(() => {
    return HOME_SYSTEMS
      .filter(s => s.maintenance && s.maintenance.daysUntilDue > 0 && s.maintenance.daysUntilDue <= 30)
      .slice(0, 4)
      .map(s => ({
        id: s.id,
        title: s.name,
        vendor: s.assignedVendor?.name || 'TBD',
        date: s.maintenance!.nextService,
        confirmed: s.assignedVendor?.isPreferred || false,
      }));
  }, []);

  // Mock recent activity
  const recentActivity = [
    { type: 'service', icon: Wrench, title: 'HVAC filter changed', date: '2 days ago' },
    { type: 'payment', icon: DollarSign, title: 'Lawn care invoice paid', date: '5 days ago', amount: 185 },
    { type: 'update', icon: FileText, title: 'Warranty uploaded for water heater', date: '1 week ago' },
    { type: 'service', icon: Wrench, title: 'Gutter cleaning completed', date: '2 weeks ago', amount: 275 },
  ];

  const renderOverview = () => (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Left Column - Home Health + Quick Stats */}
      <div className="space-y-6">
        {/* Home Health Score Card */}
        <div className="bg-white rounded-2xl border border-warm-200 p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-warm-900">Home Health</h2>
            <button onClick={() => setActiveTab('maintenance')} className="text-sm text-haven-700 hover:text-haven-800">View Details</button>
          </div>

          {/* Circular Progress */}
          <div className="flex justify-center mb-6">
            <div className="relative w-32 h-32">
              <svg className="w-full h-full transform -rotate-90">
                <circle
                  cx="64"
                  cy="64"
                  r="56"
                  stroke="#E7E5E4"
                  strokeWidth="12"
                  fill="none"
                />
                <circle
                  cx="64"
                  cy="64"
                  r="56"
                  stroke={homeHealthScore >= 70 ? '#22C55E' : homeHealthScore >= 40 ? '#F59E0B' : '#EF4444'}
                  strokeWidth="12"
                  fill="none"
                  strokeLinecap="round"
                  strokeDasharray={`${(homeHealthScore / 100) * 352} 352`}
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-4xl font-bold text-warm-900">{homeHealthScore}</span>
                <span className="text-sm text-warm-500">/ 100</span>
              </div>
            </div>
          </div>

          {/* Health Breakdown */}
          <div className="space-y-3">
            <div className="flex items-center justify-between text-sm">
              <span className="text-warm-600">Systems needing attention</span>
              <span className="font-medium text-amber-600">{maintenanceStats.dueSoon}</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-warm-600">Overdue maintenance</span>
              <span className="font-medium text-red-600">{maintenanceStats.overdue}</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-warm-600">On track</span>
              <span className="font-medium text-green-600">{maintenanceStats.onTrack}</span>
            </div>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white rounded-xl border border-warm-200 p-4">
            <p className="text-2xl font-bold text-warm-900">{HOME_SYSTEMS.length}</p>
            <p className="text-sm text-warm-500">Systems Tracked</p>
          </div>
          <div className="bg-white rounded-xl border border-warm-200 p-4">
            <p className="text-2xl font-bold text-warm-900">{VENDORS.length}</p>
            <p className="text-sm text-warm-500">Vendors</p>
          </div>
          <div className="bg-white rounded-xl border border-warm-200 p-4">
            <p className="text-2xl font-bold text-green-600">$3,400+</p>
            <p className="text-sm text-warm-500">Saved This Year</p>
          </div>
          <div className="bg-white rounded-xl border border-warm-200 p-4">
            <p className="text-2xl font-bold text-warm-900">{DOCUMENTS.length}</p>
            <p className="text-sm text-warm-500">Documents</p>
          </div>
        </div>
      </div>

      {/* Middle Column - Systems Overview */}
      <div className="space-y-6">
        <div className="bg-white rounded-2xl border border-warm-200 p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-warm-900">Systems Status</h2>
            <button onClick={() => setActiveTab('systems')} className="text-sm text-haven-700 hover:text-haven-800">View All</button>
          </div>

          <div className="space-y-3">
            {HOME_SYSTEMS.slice(0, 6).map(system => {
              const status = getStatusConfig(system.maintenance?.status || 'on-track');
              const category = getCategoryColor(system.category);
              const CategoryIcon = getCategoryIcon(system.category);
              const currentYear = new Date().getFullYear();
              const ageYears = system.installYear ? currentYear - system.installYear : 0;
              const lifespanPercent = system.expectedLifespan ? Math.min(100, (ageYears / system.expectedLifespan) * 100) : 0;
              return (
                <div
                  key={system.id}
                  className="p-3 rounded-xl border border-warm-100 hover:border-warm-200 cursor-pointer transition-colors"
                  onClick={() => setSelectedSystem(system)}
                >
                  <div className="flex items-center gap-3 mb-2">
                    <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${category.bg}`}>
                      <CategoryIcon className={`w-4 h-4 ${category.text}`} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-warm-900 truncate text-sm">{system.name}</p>
                    </div>
                    <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${status.bg} ${status.text}`}>
                      {status.label}
                    </span>
                  </div>
                  {system.installYear && system.expectedLifespan && (
                    <div className="ml-11">
                      <div className="flex items-center justify-between text-xs text-warm-400 mb-1">
                        <span>Year {ageYears} of {system.expectedLifespan}</span>
                      </div>
                      <div className="w-full bg-warm-100 rounded-full h-1.5">
                        <div
                          className={`h-1.5 rounded-full transition-all ${
                            lifespanPercent > 80 ? 'bg-red-500' : lifespanPercent > 60 ? 'bg-amber-500' : 'bg-green-500'
                          }`}
                          style={{ width: `${lifespanPercent}%` }}
                        />
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Right Column - Activity & Upcoming */}
      <div className="space-y-6">
        {/* Upcoming Maintenance */}
        <div className="bg-white rounded-2xl border border-warm-200 p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-warm-900">Upcoming</h2>
            <button onClick={() => setActiveTab('maintenance')} className="text-sm text-haven-700 hover:text-haven-800">View All</button>
          </div>

          <div className="space-y-3">
            {upcomingMaintenance.length > 0 ? upcomingMaintenance.map(item => (
              <div key={item.id} className="flex items-center gap-3 p-3 bg-warm-50 rounded-xl">
                <div className="w-12 text-center">
                  <p className="text-lg font-bold text-warm-900">{new Date(item.date).getDate()}</p>
                  <p className="text-xs text-warm-500 uppercase">{new Date(item.date).toLocaleDateString('en-US', { month: 'short' })}</p>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-warm-900 truncate">{item.title}</p>
                  <p className="text-sm text-warm-500">{item.vendor}</p>
                </div>
                <span className={`text-xs px-2 py-1 rounded-full ${
                  item.confirmed ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'
                }`}>
                  {item.confirmed ? 'Confirmed' : 'Pending'}
                </span>
              </div>
            )) : (
              <p className="text-sm text-warm-500 text-center py-4">No upcoming maintenance in the next 30 days</p>
            )}
          </div>
        </div>

        {/* Recent Activity */}
        <div className="bg-white rounded-2xl border border-warm-200 p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-warm-900">Recent Activity</h2>
          </div>

          <div className="space-y-4">
            {recentActivity.map((activity, idx) => (
              <div key={idx} className="flex items-start gap-3">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                  activity.type === 'service' ? 'bg-blue-100' :
                  activity.type === 'payment' ? 'bg-green-100' :
                  'bg-warm-100'
                }`}>
                  <activity.icon className={`w-4 h-4 ${
                    activity.type === 'service' ? 'text-blue-600' :
                    activity.type === 'payment' ? 'text-green-600' :
                    'text-warm-600'
                  }`} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-warm-900">{activity.title}</p>
                  <p className="text-xs text-warm-500">{activity.date}</p>
                </div>
                {activity.amount && (
                  <span className="text-sm font-medium text-warm-900">${activity.amount}</span>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  const renderSystems = () => (
    <div className="space-y-4">
      {Object.entries(systemsByCategory).map(([category, systems]) => {
        const isExpanded = expandedCategories.has(category);
        const categoryColor = getCategoryColor(category);
        const CategoryIcon = getCategoryIcon(category);
        return (
          <div key={category} className="bg-white rounded-xl border border-warm-200 overflow-hidden">
            <button onClick={() => toggleCategory(category)} className="w-full flex items-center justify-between p-4 hover:bg-warm-50">
              <div className="flex items-center gap-3">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${categoryColor.bg}`}><CategoryIcon className={`w-5 h-5 ${categoryColor.text}`} /></div>
                <div className="text-left"><h3 className="font-semibold text-warm-900">{getCategoryLabel(category)}</h3><p className="text-sm text-warm-500">{systems.length} items</p></div>
              </div>
              {isExpanded ? <ChevronUp className="w-5 h-5 text-warm-400" /> : <ChevronDown className="w-5 h-5 text-warm-400" />}
            </button>
            {isExpanded && (
              <div className="border-t border-warm-200 divide-y divide-warm-100">
                {systems.map(system => (
                  <button key={system.id} onClick={() => setSelectedSystem(system)} className="w-full flex items-center justify-between p-4 hover:bg-warm-50 text-left">
                    <div><p className="font-medium text-warm-900">{system.name}</p><p className="text-sm text-warm-500">{system.brand} {system.model}</p></div>
                    <ChevronRight className="w-5 h-5 text-warm-400" />
                  </button>
                ))}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );

  const renderVendors = () => (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {VENDORS.map(vendor => (
        <div key={vendor.id} className="bg-white rounded-xl border border-warm-200 p-4">
          <div className="flex items-start gap-4">
            <VendorAvatar name={vendor.name} size="lg" />
            <div className="flex-1">
              <div className="flex items-start justify-between">
                <div><h3 className="font-semibold text-warm-900">{vendor.name}</h3><p className="text-sm text-warm-500">{vendor.category}</p></div>
                {vendor.isPreferred && <span className="px-2 py-0.5 bg-haven-100 text-haven-700 text-xs font-medium rounded-full">Preferred</span>}
              </div>
              <div className="flex items-center gap-1 mt-2"><Star className="w-4 h-4 text-amber-500 fill-amber-500" /><span className="text-sm font-medium">{vendor.rating}</span><span className="text-sm text-warm-500">({vendor.reviewCount})</span></div>
              <div className="mt-3 flex gap-2">
                <a href={`tel:${vendor.phone}`} className="flex-1 flex items-center justify-center gap-2 py-2 bg-haven-50 text-haven-700 rounded-lg text-sm font-medium"><Phone className="w-4 h-4" />Call</a>
                <button className="flex-1 flex items-center justify-center gap-2 py-2 border border-warm-200 text-warm-700 rounded-lg text-sm font-medium"><MessageCircle className="w-4 h-4" />Message</button>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );

  // ============================================================================
  // MAIN RENDER
  // ============================================================================
  return (
    <div className="min-h-screen bg-warm-50 pb-24 lg:pb-8">
      <div className="bg-white border-b border-warm-200">
        <div className="max-w-7xl mx-auto">
          <div className="relative h-48 sm:h-64 overflow-hidden bg-gradient-to-br from-haven-700 to-haven-800">
            <img
              src={PROPERTY.photoUrl}
              alt={PROPERTY.address}
              className="w-full h-full object-cover"
              onError={(e) => {
                e.currentTarget.style.display = 'none';
              }}
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-transparent" />
            <div className="absolute bottom-0 left-0 right-0 p-4 sm:p-6">
              <div className="max-w-7xl mx-auto">
                <h1 className="text-xl sm:text-2xl font-bold text-white">{PROPERTY.address}</h1>
                <p className="text-white/80">{PROPERTY.city}, {PROPERTY.state} {PROPERTY.zip}</p>
                <div className="flex flex-wrap items-center gap-3 mt-2">
                  <span className="flex items-center gap-1 text-white/90 text-sm"><Bed className="w-4 h-4" /> {PROPERTY.bedrooms}</span>
                  <span className="flex items-center gap-1 text-white/90 text-sm"><Bath className="w-4 h-4" /> {PROPERTY.bathrooms}</span>
                  <span className="flex items-center gap-1 text-white/90 text-sm"><Square className="w-4 h-4" /> {PROPERTY.sqft.toLocaleString()} sqft</span>
                  <span className="flex items-center gap-1 text-white/90 text-sm"><TreePine className="w-4 h-4" /> {PROPERTY.lotSize}</span>
                </div>
              </div>
            </div>
          </div>
          <div className="px-4 sm:px-6">
            <div className="flex gap-1 overflow-x-auto pb-px -mb-px">
              {TABS.map(tab => {
                const Icon = tab.icon;
                const isActive = activeTab === tab.id;
                const badge = tab.id === 'maintenance' && (maintenanceStats.overdue + maintenanceStats.dueSoon) > 0 ? maintenanceStats.overdue + maintenanceStats.dueSoon : null;
                return (
                  <button key={tab.id} onClick={() => setActiveTab(tab.id)} className={`flex items-center gap-2 px-4 py-3 text-sm font-medium whitespace-nowrap border-b-2 transition-colors ${isActive ? 'border-haven-700 text-haven-700' : 'border-transparent text-warm-500'}`}>
                    <Icon className="w-4 h-4" />{tab.label}
                    {badge && <span className="px-1.5 py-0.5 text-xs font-bold bg-red-500 text-white rounded-full">{badge}</span>}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
        {activeTab === 'overview' && renderOverview()}
        {activeTab === 'maintenance' && renderMaintenance()}
        {activeTab === 'systems' && renderSystems()}
        {activeTab === 'vendors' && renderVendors()}
        {activeTab === 'vehicles' && renderVehicles()}
        {activeTab === 'financial' && renderFinancial()}
        {activeTab === 'documents' && renderDocuments()}
      </div>
      {selectedSystem && <SystemDetailModal system={selectedSystem} onClose={() => setSelectedSystem(null)} />}
    </div>
  );
}
