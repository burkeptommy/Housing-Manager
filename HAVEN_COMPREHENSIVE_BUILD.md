# Haven Comprehensive Build - Home Profile, Essentials Tier, Navigation Fixes

## Overview

This prompt covers ALL the following:

1. **Your Home page** - Restore tabbed interface (Systems, Vendors, Vehicles, Loans/Mortgages, Documents)
2. **Correct house image** - Use the actual 38 Bedford Rd Greenwich home from Zillow
3. **Essentials demo user** - Create full demo data for testing Essentials tier
4. **Marketing page** - Add Essentials tier information prominently
5. **Desktop navigation** - Fix Sarah tab styling to match other nav items
6. **Mobile navigation** - Proper nav for each subscription tier
7. **Manager Hub** - Create the Sarah tab for Haven+/Estate users
8. **Pricing section** - Essentials prominent, expandable Haven+/Estate

---

# PART 1: YOUR HOME PAGE - TABBED INTERFACE

## File: `apps/web/src/app/app/home/page.tsx`

Restore the tabbed interface that organizes content into: Overview, Systems, Vendors, Vehicles, Financial, Documents

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
  CreditCard,
  Landmark,
  Receipt,
  TrendingUp,
  X,
  Mail,
  Globe,
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
  // Use the actual Zillow listing photo - main exterior shot
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
  {
    id: 'plumb-3',
    name: 'Water Softener',
    category: 'plumbing',
    type: 'Whole House Water Softener',
    brand: 'Kinetico',
    model: 'Premier Series',
    installDate: 'January 2022',
    warrantyExpiry: 'January 2032',
    lastService: 'July 2024',
    nextService: 'January 2025',
    serviceInterval: 'Every 6 months',
    condition: 'excellent',
    assignedVendor: { id: 'v-2', name: "Mike's Plumbing", phone: '(203) 555-7473' },
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
  {
    id: 'appl-4',
    name: 'Washer',
    category: 'appliance',
    type: 'Front Load Washer',
    brand: 'Miele',
    model: 'W1',
    installDate: 'March 2022',
    warrantyExpiry: 'March 2024',
    condition: 'excellent',
  },
  {
    id: 'appl-5',
    name: 'Dryer',
    category: 'appliance',
    type: 'Heat Pump Dryer',
    brand: 'Miele',
    model: 'T1',
    installDate: 'March 2022',
    warrantyExpiry: 'March 2024',
    condition: 'excellent',
    lastService: 'October 2024',
    nextService: 'October 2025',
    serviceInterval: 'Annual vent cleaning',
    assignedVendor: { id: 'v-7', name: 'Dryer Vent Wizard', phone: '(203) 555-8368' },
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
  {
    id: 'ext-3',
    name: 'Exterior Paint',
    category: 'exterior',
    type: 'Benjamin Moore Exterior',
    installDate: 'May 2022',
    condition: 'good',
    notes: 'Color: White Dove OC-17',
  },
  {
    id: 'ext-4',
    name: 'Driveway',
    category: 'exterior',
    type: 'Belgian Block with Gravel',
    installDate: '2015',
    condition: 'excellent',
    notes: 'Circular driveway, approx 800 ft',
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
  {
    id: 'sec-3',
    name: 'Smart Locks',
    category: 'security',
    type: 'Smart Deadbolt',
    brand: 'Yale',
    model: 'Assure Lock 2',
    installDate: 'January 2024',
    condition: 'excellent',
    notes: 'Front, back, and garage entry doors',
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
  {
    id: 'pool-3',
    name: 'Pool Automation',
    category: 'pool',
    type: 'Smart Pool Controller',
    brand: 'Pentair',
    model: 'IntelliCenter',
    installDate: 'May 2021',
    condition: 'excellent',
    notes: 'Controls pump, heater, lights, water features',
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
    id: 'v-7',
    name: 'Dryer Vent Wizard',
    category: 'Appliance Service',
    phone: '(203) 555-8368',
    rating: 4.8,
    reviewCount: 94,
    lastUsed: 'October 2024',
    totalSpent: 350,
    isPreferred: false,
    servicesProvided: ['Dryer Vent Cleaning', 'Inspection'],
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

const TABS: { id: TabId; label: string; icon: any }[] = [
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
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);
  const [selectedVehicle, setSelectedVehicle] = useState<Vehicle | null>(null);

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
            <button className="text-sm text-haven-600 font-medium hover:text-haven-700">View All</button>
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
            <button className="text-sm text-haven-600 font-medium hover:text-haven-700">View All</button>
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
            <div
              key={vendor.id}
              className="p-4 hover:bg-warm-50 cursor-pointer transition-colors"
              onClick={() => setSelectedVendor(vendor)}
            >
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
            <div
              key={vendor.id}
              className="p-4 hover:bg-warm-50 cursor-pointer transition-colors"
              onClick={() => setSelectedVendor(vendor)}
            >
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
            className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden hover:shadow-md transition-shadow cursor-pointer"
            onClick={() => setSelectedVehicle(vehicle)}
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
          {/* Home Insurance */}
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
          
          {/* Auto Insurance */}
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

          {/* Umbrella */}
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

      {/* Modals would go here - System Detail, Vendor Detail, Vehicle Detail */}
    </div>
  );
}
```

---

# PART 2: ESSENTIALS DEMO USER

## File: `apps/web/src/data/demo-essentials-user.ts`

Create demo data for testing the Essentials tier:

```tsx
// Demo user for Haven Essentials tier testing
export const ESSENTIALS_DEMO_USER = {
  id: 'demo-essentials',
  email: 'demo-essentials@havenhome.com',
  password: 'essentials2024',
  name: 'Jennifer Walsh',
  subscription: 'essentials',
  
  household: {
    id: 'hh-essentials-demo',
    address: '127 Maple Avenue',
    city: 'Darien',
    state: 'CT',
    zip: '06820',
    propertyType: 'Single Family',
    yearBuilt: 1985,
    sqft: 2800,
    bedrooms: 4,
    bathrooms: 2.5,
    photoUrl: 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=1200&h=800&fit=crop',
    purchaseDate: 'August 2021',
    purchasePrice: 875000,
    currentValue: 1050000,
  },

  // Bills for consolidation
  bills: [
    { id: 'bill-1', vendor: 'Eversource', category: 'Electric', amount: 185, dueDay: 15 },
    { id: 'bill-2', vendor: 'Southern CT Gas', category: 'Gas', amount: 95, dueDay: 20 },
    { id: 'bill-3', vendor: 'Aquarion Water', category: 'Water', amount: 65, dueDay: 1 },
    { id: 'bill-4', vendor: 'Optimum', category: 'Internet/TV', amount: 189, dueDay: 10 },
    { id: 'bill-5', vendor: 'ADT Security', category: 'Security', amount: 45, dueDay: 5 },
    { id: 'bill-6', vendor: 'Waste Management', category: 'Trash', amount: 42, dueDay: 1 },
    { id: 'bill-7', vendor: 'TruGreen', category: 'Lawn Care', amount: 150, dueDay: 15 },
  ],
  totalMonthlyBills: 771,

  // Home systems
  systems: [
    {
      id: 'sys-1',
      name: 'Central Air Conditioning',
      category: 'hvac',
      brand: 'Lennox',
      installDate: '2019',
      nextService: 'March 2025',
      serviceInterval: 'Annually',
    },
    {
      id: 'sys-2', 
      name: 'Gas Furnace',
      category: 'hvac',
      brand: 'Lennox',
      installDate: '2019',
      nextService: 'March 2025',
      serviceInterval: 'Annually',
    },
    {
      id: 'sys-3',
      name: 'Water Heater',
      category: 'plumbing',
      brand: 'Rheem',
      installDate: '2021',
      nextService: 'August 2025',
      serviceInterval: 'Annually',
    },
    {
      id: 'sys-4',
      name: 'Roof',
      category: 'exterior',
      type: 'Asphalt Shingles',
      installDate: '2015',
      warrantyExpiry: '2040',
    },
    {
      id: 'sys-5',
      name: 'Washer/Dryer',
      category: 'appliance',
      brand: 'Samsung',
      installDate: '2022',
    },
  ],

  // Upcoming reminders
  reminders: [
    { id: 'rem-1', title: 'HVAC Filter Change', dueDate: 'January 15, 2025', recurring: 'Every 3 months' },
    { id: 'rem-2', title: 'Gutter Cleaning', dueDate: 'March 2025', recurring: 'Twice yearly' },
    { id: 'rem-3', title: 'Smoke Detector Batteries', dueDate: 'March 2025', recurring: 'Annually' },
    { id: 'rem-4', title: 'HVAC Spring Tune-up', dueDate: 'April 2025', recurring: 'Annually' },
    { id: 'rem-5', title: 'AC Ready Check', dueDate: 'May 2025', recurring: 'Annually' },
  ],

  // Vehicles
  vehicles: [
    {
      id: 'veh-1',
      name: 'Family SUV',
      year: 2021,
      make: 'Honda',
      model: 'Pilot',
      mileage: 42000,
      nextService: 'February 2025',
    },
    {
      id: 'veh-2',
      name: "Jen's Car",
      year: 2023,
      make: 'Toyota',
      model: 'Camry Hybrid',
      mileage: 18000,
      nextService: 'June 2025',
    },
  ],

  // Saved vendors
  vendors: [
    { id: 'v-1', name: 'ABC HVAC Services', category: 'HVAC', phone: '(203) 555-1234', rating: 4.7 },
    { id: 'v-2', name: 'Darien Plumbing', category: 'Plumbing', phone: '(203) 555-2345', rating: 4.5 },
    { id: 'v-3', name: 'Pro Electric', category: 'Electrical', phone: '(203) 555-3456', rating: 4.8 },
  ],
};

// Feature access by tier
export const TIER_FEATURES = {
  essentials: {
    hasBillConsolidation: true,
    hasHomeProfile: true,
    hasMaintenanceReminders: true,
    hasVendorDirectory: true,
    hasMessages: true,
    hasDocuments: true,
    hasHomeManager: false,
    hasProactiveCoordination: false,
    hasHandymanIncluded: false,
    handymanPrice: 99, // per visit
    hasProjectManagement: false,
    hasFamilyPortal: false,
  },
  plus: {
    hasBillConsolidation: true,
    hasHomeProfile: true,
    hasMaintenanceReminders: true,
    hasVendorDirectory: true,
    hasMessages: true,
    hasDocuments: true,
    hasHomeManager: true,
    hasProactiveCoordination: true,
    hasHandymanIncluded: true,
    handymanVisitsPerMonth: 1,
    hasProjectManagement: true,
    hasFamilyPortal: true,
  },
  estate: {
    hasBillConsolidation: true,
    hasHomeProfile: true,
    hasMaintenanceReminders: true,
    hasVendorDirectory: true,
    hasMessages: true,
    hasDocuments: true,
    hasHomeManager: true,
    hasProactiveCoordination: true,
    hasHandymanIncluded: true,
    handymanVisitsPerMonth: 'unlimited',
    hasProjectManagement: true,
    hasFamilyPortal: true,
    hasMultiProperty: true,
    hasConcierge: true,
    has24x7Support: true,
  },
};
```

---

# PART 3: FIX DESKTOP NAVIGATION - SARAH TAB STYLING

## File: `apps/web/src/components/app-shell/desktop-sidebar.tsx`

The Sarah tab should NOT be styled differently. It should match all other nav items:

```tsx
// WRONG - Don't do this special styling for Sarah
{item.highlight && (
  <Link
    href={item.href}
    className="flex items-center gap-3 px-3 py-2.5 rounded-xl bg-haven-50 text-haven-600 hover:bg-haven-100"
  >
    {/* Special big avatar and styling */}
  </Link>
)}

// CORRECT - Sarah tab should look like every other nav item
const navigation = [
  { name: 'Dashboard', href: '/app', icon: LayoutDashboard },
  { name: 'Your Home', href: '/app/home', icon: Home },
  { 
    name: managerFirstName || 'Sarah', 
    href: '/app/manager', 
    icon: User,
    badge: pendingRequestsCount > 0 ? pendingRequestsCount : undefined,
  },
  { name: 'Messages', href: '/app/messages', icon: MessageCircle, badge: unreadCount },
  // ... rest of nav
];

// All items rendered the same way:
{navigation.map((item) => {
  if (item.type === 'divider') {
    return (
      <div key={item.label} className="pt-4 pb-2">
        <span className="px-3 text-xs font-semibold text-warm-400 uppercase tracking-wider">
          {item.label}
        </span>
      </div>
    );
  }

  const isActive = pathname === item.href;
  const Icon = item.icon;

  return (
    <Link
      key={item.name}
      href={item.href}
      className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
        isActive
          ? 'bg-haven-100 text-haven-700'
          : 'text-warm-600 hover:bg-warm-100 hover:text-warm-900'
      }`}
    >
      <Icon className={`w-5 h-5 ${isActive ? 'text-haven-600' : 'text-warm-400'}`} />
      <span className="flex-1">{item.name}</span>
      {item.badge && item.badge > 0 && (
        <span className="px-2 py-0.5 bg-red-500 text-white text-xs font-bold rounded-full">
          {item.badge}
        </span>
      )}
    </Link>
  );
})}
```

---

# PART 4: MARKETING PAGE - ESSENTIALS PROMINENT + COMPARISON TABLE

## File: `apps/web/src/app/(marketing)/page.tsx`

Update the comparison table and pricing section to feature Essentials:

```tsx
{/* Pricing Section */}
<section id="pricing" className="py-16 sm:py-24 bg-white">
  <div className="max-w-5xl mx-auto px-4 sm:px-6">
    <div className="text-center mb-12">
      <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
        Simple, Transparent Pricing
      </h2>
      <p className="text-lg text-warm-600 mt-4 max-w-2xl mx-auto">
        Start with Essentials for $39/month. Upgrade when you're ready for a dedicated home manager.
      </p>
    </div>

    <div className="space-y-4">
      {/* ESSENTIALS - Primary Card */}
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
              <p className="text-sm text-warm-500">No setup fee • Cancel anytime</p>
            </div>
          </div>

          <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-3">
            {[
              { icon: DollarSign, text: 'Bill consolidation — one monthly payment' },
              { icon: Home, text: 'Complete home systems inventory' },
              { icon: Clock, text: 'Maintenance reminders & scheduling' },
              { icon: Users, text: 'Vendor directory with neighbor reviews' },
              { icon: FileText, text: 'Document storage & warranties' },
              { icon: Wrench, text: 'Pay-per-use handyman visits ($99)' },
            ].map((feature, idx) => (
              <div key={idx} className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-haven-100 flex items-center justify-center flex-shrink-0">
                  <feature.icon className="w-4 h-4 text-haven-600" />
                </div>
                <span className="text-sm text-warm-700">{feature.text}</span>
              </div>
            ))}
          </div>

          <div className="mt-6 flex flex-col sm:flex-row gap-3">
            <button className="flex-1 py-3 bg-haven-600 text-white font-semibold rounded-xl hover:bg-haven-700 transition-colors">
              Get Started Free
            </button>
            <button className="py-3 px-6 border border-warm-200 text-warm-700 font-medium rounded-xl hover:bg-warm-50 transition-colors">
              Learn More
            </button>
          </div>
        </div>
      </div>

      {/* HAVEN+ - Expandable */}
      <ExpandablePricingCard
        name="Haven+"
        price={349}
        tagline="Part-time home manager included"
        icon={Star}
        iconBg="bg-purple-100"
        iconColor="text-purple-600"
        features={[
          'Everything in Essentials',
          'Dedicated Home Manager (~10 hrs/month)',
          'Proactive vendor coordination',
          'Monthly handyman visit included',
          'Project coordination',
          'Priority support',
        ]}
        buttonText="Upgrade to Haven+"
        buttonColor="bg-purple-600 hover:bg-purple-700"
      />

      {/* HAVEN ESTATE - Expandable */}
      <ExpandablePricingCard
        name="Haven Estate"
        price={749}
        tagline="Full-time manager for complex households"
        icon={Crown}
        iconBg="bg-amber-100"
        iconColor="text-amber-600"
        features={[
          'Everything in Haven+',
          'Dedicated full-time manager',
          'Unlimited vendor coordination',
          'Multi-property support',
          'Unlimited handyman visits',
          'Concierge services',
          '24/7 emergency response',
        ]}
        buttonText="Contact Sales"
        buttonColor="bg-amber-600 hover:bg-amber-700"
      />
    </div>

    <div className="mt-8 text-center">
      <p className="text-sm text-warm-500">
        30-day money-back guarantee • No long-term contracts
      </p>
    </div>
  </div>
</section>
```

---

# PART 5: UPDATED COMPARISON TABLE

Include Essentials in the comparison:

```tsx
{/* Mobile: Comparison Cards */}
<div className="lg:hidden space-y-3">
  {[
    { feature: 'Monthly Cost', essentials: '$39', plus: '$349', others: '$375+' },
    { feature: 'Setup Fee', essentials: '$0', plus: '$0', others: '$3K-$5K' },
    { feature: 'Bill Consolidation', essentials: '✓', plus: '✓', others: '✗', havenBetter: true },
    { feature: 'Home Systems Tracking', essentials: '✓', plus: '✓', others: '✓' },
    { feature: 'Maintenance Reminders', essentials: '✓', plus: '✓', others: '✓' },
    { feature: 'Home Manager', essentials: 'Self-service', plus: 'Dedicated', others: '✗', havenBetter: true },
    { feature: 'Vendor Coordination', essentials: 'DIY', plus: 'We handle it', others: '✗', havenBetter: true },
    { feature: 'Handyman Visits', essentials: '$99/visit', plus: 'Included', others: '✗' },
  ].map((row, idx) => (
    <div key={idx} className={`bg-white rounded-xl border overflow-hidden ${row.havenBetter ? 'border-haven-300' : 'border-warm-200'}`}>
      <div className="bg-warm-100 px-4 py-2">
        <span className="font-medium text-warm-700 text-sm">{row.feature}</span>
      </div>
      <div className="grid grid-cols-3 divide-x divide-warm-100">
        <div className="p-3 text-center bg-haven-50/30">
          <div className="text-xs text-haven-600 mb-1">Essentials</div>
          <div className="text-sm font-medium text-haven-700">{row.essentials}</div>
        </div>
        <div className="p-3 text-center bg-haven-50">
          <div className="text-xs text-haven-600 mb-1">Haven+</div>
          <div className="text-sm font-medium text-haven-700">{row.plus}</div>
        </div>
        <div className="p-3 text-center">
          <div className="text-xs text-warm-400 mb-1">Others</div>
          <div className="text-sm text-warm-500">{row.others}</div>
        </div>
      </div>
    </div>
  ))}
</div>
```

---

# SUMMARY CHECKLIST

## Files to Create:
1. `apps/web/src/app/app/home/page.tsx` - Tabbed "Your Home" page
2. `apps/web/src/data/demo-essentials-user.ts` - Essentials demo user data

## Files to Update:
1. `apps/web/src/components/app-shell/desktop-sidebar.tsx` - Fix Sarah tab styling
2. `apps/web/src/components/app-shell/mobile-nav.tsx` - Tier-based navigation
3. `apps/web/src/app/(marketing)/page.tsx` - Add Essentials to pricing & comparison

## Key Changes:
- **Your Home page**: Tabbed interface (Overview, Systems, Vendors, Vehicles, Financial, Documents)
- **House image**: Use actual Zillow listing photo for 38 Bedford Rd
- **Essentials demo**: Full demo user data for testing
- **Sarah tab**: Same styling as other nav items (not special/larger)
- **Marketing pricing**: Essentials prominent, Haven+/Estate in expandable dropdowns
- **Comparison table**: Include Essentials column

---

## Run in Claude Code:

```
Read and apply HAVEN_COMPREHENSIVE_BUILD.md

This is a comprehensive update covering:

1. YOUR HOME PAGE - Restore tabbed interface with:
   - Overview tab (property card, quick stats, upcoming maintenance)
   - Systems tab (HVAC, Plumbing, Electrical, etc. with expandable categories)
   - Vendors tab (preferred vendors, all vendors)
   - Vehicles tab (cards for each vehicle)
   - Financial tab (mortgages, loans, insurance, property value)
   - Documents tab (organized by category)

2. CORRECT HOUSE IMAGE - Use the actual Zillow photo from:
   https://www.zillow.com/homedetails/38-Bedford-Rd-Greenwich-CT-06831/240524148_zpid/
   Photo URL: https://photos.zillowstatic.com/fp/c2a65e47b1e40de4e3dbf3ee2763b256-cc_ft_1536.webp

3. ESSENTIALS DEMO USER - Create demo data for Jennifer Walsh testing Essentials tier

4. FIX SARAH TAB - Make it the SAME styling as other nav items (not special/larger)

5. MARKETING PAGE - Add Essentials tier prominently with expandable Haven+/Estate

6. COMPARISON TABLE - Include Essentials, Haven+, and Others columns

Make sure all mock data is consistent (Bob Morrison for Haven+, Jennifer Walsh for Essentials).
```
