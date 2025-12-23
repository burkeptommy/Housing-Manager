'use client';

import { useState, useRef, useCallback } from 'react';
import Map, { Marker, Popup, NavigationControl } from 'react-map-gl/mapbox';
import type { MapRef } from 'react-map-gl/mapbox';
import 'mapbox-gl/dist/mapbox-gl.css';
import {
  Search,
  MapPin,
  Star,
  Filter,
  Grid3X3,
  Map as MapIcon,
  Phone,
  MessageSquare,
  CheckCircle2,
  Shield,
  Clock,
  Users,
  ChevronDown,
  X,
  Hammer,
  Wrench,
  Zap,
  Droplets,
  Paintbrush,
  TreePine,
  Wind,
  Home,
  Sparkles,
  Heart,
  ExternalLink,
  Camera,
  DollarSign,
} from 'lucide-react';
import { getDemoImage, getVendorWorkImage } from '@/lib/imageUtils';
import { getVendorAvatar } from '@/lib/avatars';

// ============================================================================
// TYPES
// ============================================================================

type ViewMode = 'map' | 'grid';
type VendorTrade = 'all' | 'plumber' | 'electrician' | 'landscaper' | 'painter' | 'hvac' | 'handyman' | 'roofer' | 'cleaner';
type SortOption = 'rating' | 'neighbors' | 'nearest' | 'projects';
type PriceTier = '$' | '$$' | '$$$';

interface Vendor {
  id: string;
  name: string;
  trade: VendorTrade;
  rating: number;
  reviewCount: number;
  priceTier: PriceTier;
  verified: boolean;
  havenTrusted: boolean;
  logoUrl: string;
  coverUrl: string;
  location: { lat: number; lng: number };
  address: string;
  distance: number;
  phone: string;
  responseTime: string;
  onTimeRate: number;
  neighborsUsed: number;
  totalProjects: number;
  recentProjects: NeighborProject[];
  specialties: string[];
}

interface NeighborProject {
  id: string;
  vendorId: string;
  title: string;
  category: string;
  beforeImage?: string;
  afterImage: string;
  cost: PriceTier;
  completedAt: string;
  neighborName: string;
  rating: number;
  review?: string;
}

interface TradeFilter {
  id: VendorTrade;
  label: string;
  icon: typeof Wrench;
  color: string;
}

// ============================================================================
// CONSTANTS
// ============================================================================

const MAPBOX_TOKEN = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || '';

const tradeFilters: TradeFilter[] = [
  { id: 'all', label: 'All Trades', icon: Home, color: 'bg-warm-100 text-warm-700' },
  { id: 'plumber', label: 'Plumbing', icon: Droplets, color: 'bg-blue-100 text-blue-700' },
  { id: 'electrician', label: 'Electrical', icon: Zap, color: 'bg-yellow-100 text-yellow-700' },
  { id: 'hvac', label: 'HVAC', icon: Wind, color: 'bg-cyan-100 text-cyan-700' },
  { id: 'landscaper', label: 'Landscaping', icon: TreePine, color: 'bg-green-100 text-green-700' },
  { id: 'painter', label: 'Painting', icon: Paintbrush, color: 'bg-purple-100 text-purple-700' },
  { id: 'handyman', label: 'Handyman', icon: Hammer, color: 'bg-orange-100 text-orange-700' },
  { id: 'roofer', label: 'Roofing', icon: Home, color: 'bg-red-100 text-red-700' },
  { id: 'cleaner', label: 'Cleaning', icon: Sparkles, color: 'bg-pink-100 text-pink-700' },
];

// Greenwich, CT location
const currentUserLocation = { lat: 41.0534, lng: -73.5387 };

const mockVendors: Vendor[] = [
  {
    id: 'v1',
    name: "Mike's Plumbing Pro",
    trade: 'plumber',
    rating: 4.9,
    reviewCount: 127,
    priceTier: '$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'mikes-plumbing-v1'),
    coverUrl: getVendorWorkImage('plumber', 'mikes-cover', 400, 200),
    location: { lat: 41.0567, lng: -73.5412 },
    address: 'Greenwich, CT',
    distance: 0.8,
    phone: '(203) 555-0123',
    responseTime: 'Usually responds in 1 hour',
    onTimeRate: 98,
    neighborsUsed: 12,
    totalProjects: 89,
    specialties: ['Emergency Repairs', 'Water Heaters', 'Bathroom Remodels'],
    recentProjects: [
      {
        id: 'p1',
        vendorId: 'v1',
        title: 'Master Bath Renovation',
        category: 'Plumbing',
        beforeImage: getDemoImage('bathroom', 300, 200, 'bath-before-1'),
        afterImage: getDemoImage('bathroom', 300, 200, 'bath-after-1'),
        cost: '$$$',
        completedAt: '2024-11-15',
        neighborName: 'A neighbor on Round Hill Rd',
        rating: 5,
        review: 'Exceptional work! Mike and his team transformed our bathroom.',
      },
    ],
  },
  {
    id: 'v2',
    name: 'Country Landscape Design',
    trade: 'landscaper',
    rating: 4.8,
    reviewCount: 203,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'country-landscape-v2'),
    coverUrl: getVendorWorkImage('landscaper', 'landscape-cover', 400, 200),
    location: { lat: 41.0489, lng: -73.5501 },
    address: 'Old Greenwich, CT',
    distance: 1.2,
    phone: '(203) 555-5296',
    responseTime: 'Usually responds same day',
    onTimeRate: 95,
    neighborsUsed: 23,
    totalProjects: 156,
    specialties: ['Garden Design', 'Hardscaping', 'Outdoor Lighting'],
    recentProjects: [
      {
        id: 'p2',
        vendorId: 'v2',
        title: 'Backyard Transformation',
        category: 'Landscaping',
        beforeImage: getDemoImage('backyard', 300, 200, 'yard-before-1'),
        afterImage: getDemoImage('backyard', 300, 200, 'yard-after-1'),
        cost: '$$$',
        completedAt: '2024-10-28',
        neighborName: 'A neighbor on Lake Ave',
        rating: 5,
      },
    ],
  },
  {
    id: 'v3',
    name: 'Elite Electric Services',
    trade: 'electrician',
    rating: 4.7,
    reviewCount: 89,
    priceTier: '$$',
    verified: true,
    havenTrusted: false,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'elite-electric-v3'),
    coverUrl: getVendorWorkImage('electrician', 'electric-cover', 400, 200),
    location: { lat: 41.0612, lng: -73.5289 },
    address: 'Cos Cob, CT',
    distance: 1.5,
    phone: '(203) 555-7890',
    responseTime: 'Usually responds in 2 hours',
    onTimeRate: 92,
    neighborsUsed: 8,
    totalProjects: 67,
    specialties: ['Panel Upgrades', 'EV Charger Install', 'Smart Home Wiring'],
    recentProjects: [],
  },
  {
    id: 'v4',
    name: 'Comfort Zone HVAC',
    trade: 'hvac',
    rating: 4.9,
    reviewCount: 156,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'comfort-zone-v4'),
    coverUrl: getVendorWorkImage('hvac', 'hvac-cover', 400, 200),
    location: { lat: 41.0445, lng: -73.5556 },
    address: 'Riverside, CT',
    distance: 1.8,
    phone: '(203) 555-4567',
    responseTime: 'Usually responds in 30 min',
    onTimeRate: 99,
    neighborsUsed: 18,
    totalProjects: 234,
    specialties: ['AC Installation', 'Furnace Repair', 'Ductwork'],
    recentProjects: [],
  },
  {
    id: 'v5',
    name: 'Perfect Painters LLC',
    trade: 'painter',
    rating: 4.6,
    reviewCount: 72,
    priceTier: '$$',
    verified: true,
    havenTrusted: false,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'perfect-painters-v5'),
    coverUrl: getVendorWorkImage('painter', 'paint-cover', 400, 200),
    location: { lat: 41.0523, lng: -73.5234 },
    address: 'Greenwich, CT',
    distance: 0.9,
    phone: '(203) 555-3456',
    responseTime: 'Usually responds same day',
    onTimeRate: 88,
    neighborsUsed: 6,
    totalProjects: 45,
    specialties: ['Interior Painting', 'Cabinet Refinishing', 'Wallpaper'],
    recentProjects: [],
  },
  {
    id: 'v6',
    name: 'Handy Dan Services',
    trade: 'handyman',
    rating: 4.8,
    reviewCount: 198,
    priceTier: '$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'handy-dan-v6'),
    coverUrl: getVendorWorkImage('handyman', 'handy-cover', 400, 200),
    location: { lat: 41.0498, lng: -73.5445 },
    address: 'Greenwich, CT',
    distance: 0.5,
    phone: '(203) 555-8901',
    responseTime: 'Usually responds in 1 hour',
    onTimeRate: 94,
    neighborsUsed: 31,
    totalProjects: 312,
    specialties: ['Minor Repairs', 'Assembly', 'Mounting', 'Odd Jobs'],
    recentProjects: [],
  },
  // Roofing
  {
    id: 'v7',
    name: 'Ace Roofing Co.',
    trade: 'roofer',
    rating: 4.9,
    reviewCount: 312,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'ace-roofing-v7'),
    coverUrl: getVendorWorkImage('roofer', 'ace-roof-cover', 400, 200),
    location: { lat: 41.0589, lng: -73.5378 },
    address: 'Greenwich, CT',
    distance: 0.7,
    phone: '(203) 555-7777',
    responseTime: 'Usually responds in 2 hours',
    onTimeRate: 97,
    neighborsUsed: 45,
    totalProjects: 234,
    specialties: ['Roof Replacement', 'Storm Damage', 'Gutter Installation'],
    recentProjects: [],
  },
  {
    id: 'v8',
    name: 'Top Notch Roofing',
    trade: 'roofer',
    rating: 4.6,
    reviewCount: 89,
    priceTier: '$$',
    verified: true,
    havenTrusted: false,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'top-notch-v8'),
    coverUrl: getVendorWorkImage('roofer', 'topnotch-cover', 400, 200),
    location: { lat: 41.0412, lng: -73.5612 },
    address: 'Stamford, CT',
    distance: 2.3,
    phone: '(203) 555-8888',
    responseTime: 'Usually responds same day',
    onTimeRate: 91,
    neighborsUsed: 8,
    totalProjects: 67,
    specialties: ['Shingle Repair', 'Flat Roofs', 'Skylights'],
    recentProjects: [],
  },
  // Cleaning
  {
    id: 'v9',
    name: 'Sparkle Clean CT',
    trade: 'cleaner',
    rating: 4.8,
    reviewCount: 245,
    priceTier: '$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'sparkle-clean-v9'),
    coverUrl: getVendorWorkImage('cleaner', 'sparkle-cover', 400, 200),
    location: { lat: 41.0501, lng: -73.5401 },
    address: 'Greenwich, CT',
    distance: 0.4,
    phone: '(203) 555-2222',
    responseTime: 'Usually responds in 1 hour',
    onTimeRate: 96,
    neighborsUsed: 38,
    totalProjects: 456,
    specialties: ['Deep Cleaning', 'Move-in/Move-out', 'Regular Service'],
    recentProjects: [],
  },
  {
    id: 'v10',
    name: 'Molly Maid Greenwich',
    trade: 'cleaner',
    rating: 4.7,
    reviewCount: 178,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'molly-maid-v10'),
    coverUrl: getVendorWorkImage('cleaner', 'molly-cover', 400, 200),
    location: { lat: 41.0478, lng: -73.5512 },
    address: 'Old Greenwich, CT',
    distance: 1.1,
    phone: '(203) 555-3333',
    responseTime: 'Usually responds same day',
    onTimeRate: 98,
    neighborsUsed: 52,
    totalProjects: 789,
    specialties: ['Eco-Friendly', 'Weekly Service', 'Special Events'],
    recentProjects: [],
  },
  // More Plumbers
  {
    id: 'v11',
    name: 'Quick Fix Plumbing',
    trade: 'plumber',
    rating: 4.5,
    reviewCount: 67,
    priceTier: '$',
    verified: true,
    havenTrusted: false,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'quick-fix-v11'),
    coverUrl: getVendorWorkImage('plumber', 'quickfix-cover', 400, 200),
    location: { lat: 41.0623, lng: -73.5234 },
    address: 'Cos Cob, CT',
    distance: 1.8,
    phone: '(203) 555-4444',
    responseTime: 'Usually responds in 30 min',
    onTimeRate: 89,
    neighborsUsed: 5,
    totalProjects: 45,
    specialties: ['Emergency Repairs', 'Drain Cleaning', 'Leaks'],
    recentProjects: [],
  },
  {
    id: 'v12',
    name: 'Premium Plumbing Solutions',
    trade: 'plumber',
    rating: 4.9,
    reviewCount: 189,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'premium-plumb-v12'),
    coverUrl: getVendorWorkImage('plumber', 'premium-cover', 400, 200),
    location: { lat: 41.0534, lng: -73.5287 },
    address: 'Greenwich, CT',
    distance: 0.6,
    phone: '(203) 555-5555',
    responseTime: 'Usually responds in 2 hours',
    onTimeRate: 99,
    neighborsUsed: 28,
    totalProjects: 156,
    specialties: ['Luxury Bathrooms', 'Water Filtration', 'Gas Lines'],
    recentProjects: [],
  },
  // More Electricians
  {
    id: 'v13',
    name: 'Bright Spark Electric',
    trade: 'electrician',
    rating: 4.8,
    reviewCount: 134,
    priceTier: '$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'bright-spark-v13'),
    coverUrl: getVendorWorkImage('electrician', 'brightspark-cover', 400, 200),
    location: { lat: 41.0556, lng: -73.5445 },
    address: 'Greenwich, CT',
    distance: 0.5,
    phone: '(203) 555-6666',
    responseTime: 'Usually responds in 1 hour',
    onTimeRate: 95,
    neighborsUsed: 22,
    totalProjects: 98,
    specialties: ['Panel Upgrades', 'Lighting Design', 'Generator Install'],
    recentProjects: [],
  },
  {
    id: 'v14',
    name: 'Tesla Certified Electricians',
    trade: 'electrician',
    rating: 4.9,
    reviewCount: 78,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'tesla-cert-v14'),
    coverUrl: getVendorWorkImage('electrician', 'tesla-cover', 400, 200),
    location: { lat: 41.0489, lng: -73.5567 },
    address: 'Riverside, CT',
    distance: 1.4,
    phone: '(203) 555-9999',
    responseTime: 'Usually responds same day',
    onTimeRate: 100,
    neighborsUsed: 15,
    totalProjects: 45,
    specialties: ['EV Chargers', 'Solar Systems', 'Smart Home'],
    recentProjects: [],
  },
  // More Landscapers
  {
    id: 'v15',
    name: 'Green Thumb Gardens',
    trade: 'landscaper',
    rating: 4.6,
    reviewCount: 156,
    priceTier: '$$',
    verified: true,
    havenTrusted: false,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'green-thumb-v15'),
    coverUrl: getVendorWorkImage('landscaper', 'greenthumb-cover', 400, 200),
    location: { lat: 41.0567, lng: -73.5312 },
    address: 'Greenwich, CT',
    distance: 0.9,
    phone: '(203) 555-1234',
    responseTime: 'Usually responds same day',
    onTimeRate: 92,
    neighborsUsed: 19,
    totalProjects: 123,
    specialties: ['Garden Design', 'Lawn Care', 'Tree Service'],
    recentProjects: [],
  },
  {
    id: 'v16',
    name: 'Estate Grounds Maintenance',
    trade: 'landscaper',
    rating: 4.9,
    reviewCount: 267,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'estate-grounds-v16'),
    coverUrl: getVendorWorkImage('landscaper', 'estate-cover', 400, 200),
    location: { lat: 41.0423, lng: -73.5623 },
    address: 'Old Greenwich, CT',
    distance: 1.6,
    phone: '(203) 555-5678',
    responseTime: 'Usually responds in 2 hours',
    onTimeRate: 98,
    neighborsUsed: 67,
    totalProjects: 345,
    specialties: ['Estate Maintenance', 'Water Features', 'Masonry'],
    recentProjects: [],
  },
  // More HVAC
  {
    id: 'v17',
    name: 'Arctic Air HVAC',
    trade: 'hvac',
    rating: 4.7,
    reviewCount: 98,
    priceTier: '$$',
    verified: true,
    havenTrusted: false,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'arctic-air-v17'),
    coverUrl: getVendorWorkImage('hvac', 'arctic-cover', 400, 200),
    location: { lat: 41.0601, lng: -73.5189 },
    address: 'Stamford, CT',
    distance: 2.1,
    phone: '(203) 555-2468',
    responseTime: 'Usually responds in 1 hour',
    onTimeRate: 93,
    neighborsUsed: 11,
    totalProjects: 78,
    specialties: ['AC Repair', 'Heat Pumps', 'Ductless Systems'],
    recentProjects: [],
  },
  // More Painters
  {
    id: 'v18',
    name: 'Brush Masters Painting',
    trade: 'painter',
    rating: 4.8,
    reviewCount: 145,
    priceTier: '$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'brush-masters-v18'),
    coverUrl: getVendorWorkImage('painter', 'brushmasters-cover', 400, 200),
    location: { lat: 41.0512, lng: -73.5456 },
    address: 'Greenwich, CT',
    distance: 0.3,
    phone: '(203) 555-1357',
    responseTime: 'Usually responds same day',
    onTimeRate: 94,
    neighborsUsed: 25,
    totalProjects: 112,
    specialties: ['Interior', 'Exterior', 'Deck Staining'],
    recentProjects: [],
  },
  {
    id: 'v19',
    name: 'Fine Finish Painters',
    trade: 'painter',
    rating: 4.9,
    reviewCount: 89,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'fine-finish-v19'),
    coverUrl: getVendorWorkImage('painter', 'finefinish-cover', 400, 200),
    location: { lat: 41.0478, lng: -73.5523 },
    address: 'Old Greenwich, CT',
    distance: 1.0,
    phone: '(203) 555-7531',
    responseTime: 'Usually responds in 2 hours',
    onTimeRate: 97,
    neighborsUsed: 18,
    totalProjects: 67,
    specialties: ['Faux Finishes', 'Murals', 'Historic Restoration'],
    recentProjects: [],
  },
  // More Handymen
  {
    id: 'v20',
    name: 'Mr. Fix-It Greenwich',
    trade: 'handyman',
    rating: 4.7,
    reviewCount: 234,
    priceTier: '$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'mr-fixit-v20'),
    coverUrl: getVendorWorkImage('handyman', 'mrfixit-cover', 400, 200),
    location: { lat: 41.0545, lng: -73.5389 },
    address: 'Greenwich, CT',
    distance: 0.2,
    phone: '(203) 555-9876',
    responseTime: 'Usually responds in 30 min',
    onTimeRate: 95,
    neighborsUsed: 43,
    totalProjects: 567,
    specialties: ['Small Repairs', 'Furniture Assembly', 'TV Mounting'],
    recentProjects: [],
  },
  {
    id: 'v21',
    name: 'Home Pro Services',
    trade: 'handyman',
    rating: 4.5,
    reviewCount: 67,
    priceTier: '$$',
    verified: true,
    havenTrusted: false,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'home-pro-v21'),
    coverUrl: getVendorWorkImage('handyman', 'homepro-cover', 400, 200),
    location: { lat: 41.0623, lng: -73.5267 },
    address: 'Cos Cob, CT',
    distance: 1.7,
    phone: '(203) 555-6543',
    responseTime: 'Usually responds same day',
    onTimeRate: 88,
    neighborsUsed: 7,
    totalProjects: 89,
    specialties: ['Drywall', 'Tile Repair', 'Carpentry'],
    recentProjects: [],
  },
  // Additional specialty vendors
  {
    id: 'v22',
    name: 'Pool Paradise CT',
    trade: 'handyman', // Using handyman since pool isn't a defined trade
    rating: 4.9,
    reviewCount: 156,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'pool-paradise-v22'),
    coverUrl: getDemoImage('backyard', 400, 200, 'pool-cover'),
    location: { lat: 41.0456, lng: -73.5534 },
    address: 'Riverside, CT',
    distance: 1.3,
    phone: '(203) 555-7890',
    responseTime: 'Usually responds in 2 hours',
    onTimeRate: 99,
    neighborsUsed: 34,
    totalProjects: 178,
    specialties: ['Pool Opening', 'Pool Closing', 'Equipment Repair'],
    recentProjects: [],
  },
  {
    id: 'v23',
    name: 'Security Systems Plus',
    trade: 'electrician',
    rating: 4.8,
    reviewCount: 89,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'security-plus-v23'),
    coverUrl: getDemoImage('house-exterior', 400, 200, 'security-cover'),
    location: { lat: 41.0534, lng: -73.5412 },
    address: 'Greenwich, CT',
    distance: 0.4,
    phone: '(203) 555-4321',
    responseTime: 'Usually responds in 1 hour',
    onTimeRate: 96,
    neighborsUsed: 21,
    totalProjects: 134,
    specialties: ['Alarm Systems', 'Camera Install', 'Smart Locks'],
    recentProjects: [],
  },
  {
    id: 'v24',
    name: 'Window World CT',
    trade: 'handyman',
    rating: 4.6,
    reviewCount: 112,
    priceTier: '$$',
    verified: true,
    havenTrusted: false,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'window-world-v24'),
    coverUrl: getDemoImage('house-exterior', 400, 200, 'window-cover'),
    location: { lat: 41.0589, lng: -73.5289 },
    address: 'Greenwich, CT',
    distance: 0.8,
    phone: '(203) 555-8765',
    responseTime: 'Usually responds same day',
    onTimeRate: 91,
    neighborsUsed: 14,
    totalProjects: 89,
    specialties: ['Window Replacement', 'Glass Repair', 'Screens'],
    recentProjects: [],
  },
  {
    id: 'v25',
    name: 'Floor Masters LLC',
    trade: 'handyman',
    rating: 4.9,
    reviewCount: 178,
    priceTier: '$$$',
    verified: true,
    havenTrusted: true,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'floor-masters-v25'),
    coverUrl: getDemoImage('living-room', 400, 200, 'floor-cover'),
    location: { lat: 41.0501, lng: -73.5478 },
    address: 'Old Greenwich, CT',
    distance: 1.0,
    phone: '(203) 555-3210',
    responseTime: 'Usually responds in 2 hours',
    onTimeRate: 98,
    neighborsUsed: 29,
    totalProjects: 145,
    specialties: ['Hardwood', 'Tile Installation', 'Refinishing'],
    recentProjects: [],
  },
  {
    id: 'v26',
    name: 'Garage Door Experts',
    trade: 'handyman',
    rating: 4.7,
    reviewCount: 67,
    priceTier: '$$',
    verified: true,
    havenTrusted: false,
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'garage-door-v26'),
    coverUrl: getDemoImage('house-exterior', 400, 200, 'garage-cover'),
    location: { lat: 41.0623, lng: -73.5345 },
    address: 'Cos Cob, CT',
    distance: 1.5,
    phone: '(203) 555-2109',
    responseTime: 'Usually responds in 1 hour',
    onTimeRate: 93,
    neighborsUsed: 9,
    totalProjects: 56,
    specialties: ['Garage Door Repair', 'Opener Install', 'Spring Replacement'],
    recentProjects: [],
  },
];

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function VendorDiscoveryPage() {
  const [viewMode, setViewMode] = useState<ViewMode>('map');
  const [selectedTrade, setSelectedTrade] = useState<VendorTrade>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<SortOption>('neighbors');
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);
  const mapRef = useRef<MapRef>(null);

  // Filter vendors
  const filteredVendors = mockVendors.filter(v => {
    if (selectedTrade !== 'all' && v.trade !== selectedTrade) return false;
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      return v.name.toLowerCase().includes(query) ||
             v.specialties.some(s => s.toLowerCase().includes(query));
    }
    return true;
  });

  // Sort vendors
  const sortedVendors = [...filteredVendors].sort((a, b) => {
    switch (sortBy) {
      case 'rating': return b.rating - a.rating;
      case 'neighbors': return b.neighborsUsed - a.neighborsUsed;
      case 'nearest': return a.distance - b.distance;
      case 'projects': return b.totalProjects - a.totalProjects;
      default: return 0;
    }
  });

  const flyToVendor = useCallback((vendor: Vendor) => {
    mapRef.current?.flyTo({
      center: [vendor.location.lng, vendor.location.lat],
      zoom: 15,
      duration: 1000,
    });
    setSelectedVendor(vendor);
  }, []);

  return (
    <div className="min-h-screen bg-warm-50">
      {/* Header */}
      <div className="bg-white border-b border-warm-200 sticky top-0 z-20">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-2xl font-bold text-warm-900">Find Contractors</h1>
              <p className="text-sm text-warm-500">Trusted pros used by your neighbors</p>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setViewMode('map')}
                className={`p-2 rounded-lg ${viewMode === 'map' ? 'bg-haven-100 text-haven-700' : 'text-warm-400 hover:bg-warm-100'}`}
              >
                <MapIcon className="w-5 h-5" />
              </button>
              <button
                onClick={() => setViewMode('grid')}
                className={`p-2 rounded-lg ${viewMode === 'grid' ? 'bg-haven-100 text-haven-700' : 'text-warm-400 hover:bg-warm-100'}`}
              >
                <Grid3X3 className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Search */}
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-warm-400" />
            <input
              type="text"
              placeholder="Search by name or specialty..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 border border-warm-300 rounded-xl focus:ring-2 focus:ring-haven-500 focus:border-transparent"
            />
          </div>

          {/* Trade Filters - Horizontal Scroll */}
          <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 scrollbar-hide">
            {tradeFilters.map(trade => (
              <button
                key={trade.id}
                onClick={() => setSelectedTrade(trade.id)}
                className={`flex items-center gap-2 px-4 py-2 rounded-full whitespace-nowrap transition-all ${
                  selectedTrade === trade.id
                    ? 'bg-haven-600 text-white'
                    : 'bg-warm-100 text-warm-600 hover:bg-warm-200'
                }`}
              >
                <trade.icon className="w-4 h-4" />
                <span className="text-sm font-medium">{trade.label}</span>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto">
        {viewMode === 'map' ? (
          <div className="flex flex-col lg:flex-row h-[calc(100vh-200px)]">
            {/* Map */}
            <div className="flex-1 relative">
              <Map
                ref={mapRef}
                mapboxAccessToken={MAPBOX_TOKEN}
                initialViewState={{
                  latitude: currentUserLocation.lat,
                  longitude: currentUserLocation.lng,
                  zoom: 13,
                }}
                style={{ width: '100%', height: '100%' }}
                mapStyle="mapbox://styles/mapbox/light-v11"
              >
                <NavigationControl position="top-right" />

                {/* User location marker */}
                <Marker latitude={currentUserLocation.lat} longitude={currentUserLocation.lng}>
                  <div className="w-4 h-4 bg-blue-500 rounded-full border-2 border-white shadow-lg" />
                </Marker>

                {/* Vendor markers */}
                {sortedVendors.map(vendor => (
                  <Marker
                    key={vendor.id}
                    latitude={vendor.location.lat}
                    longitude={vendor.location.lng}
                    onClick={() => setSelectedVendor(vendor)}
                  >
                    <div className={`
                      w-10 h-10 rounded-full flex items-center justify-center cursor-pointer
                      transition-transform hover:scale-110
                      ${vendor.havenTrusted ? 'bg-haven-600' : 'bg-warm-600'}
                      ${selectedVendor?.id === vendor.id ? 'ring-4 ring-haven-300 scale-110' : ''}
                    `}>
                      {vendor.havenTrusted && (
                        <Shield className="w-5 h-5 text-white" />
                      )}
                      {!vendor.havenTrusted && (
                        <Wrench className="w-5 h-5 text-white" />
                      )}
                    </div>
                  </Marker>
                ))}

                {/* Popup for selected vendor */}
                {selectedVendor && (
                  <Popup
                    latitude={selectedVendor.location.lat}
                    longitude={selectedVendor.location.lng}
                    onClose={() => setSelectedVendor(null)}
                    closeButton={true}
                    closeOnClick={false}
                    offset={25}
                  >
                    <VendorPopup vendor={selectedVendor} />
                  </Popup>
                )}
              </Map>
            </div>

            {/* Vendor List Sidebar */}
            <div className="w-full lg:w-96 bg-white border-l border-warm-200 overflow-y-auto">
              <div className="p-4 border-b border-warm-200">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-warm-600">
                    {sortedVendors.length} contractors found
                  </span>
                  <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value as SortOption)}
                    className="text-sm border-none bg-transparent text-haven-600 font-medium focus:ring-0"
                  >
                    <option value="neighbors">Most Used by Neighbors</option>
                    <option value="rating">Highest Rated</option>
                    <option value="nearest">Nearest</option>
                    <option value="projects">Most Projects</option>
                  </select>
                </div>
              </div>
              <div className="divide-y divide-warm-100">
                {sortedVendors.map(vendor => (
                  <VendorListItem
                    key={vendor.id}
                    vendor={vendor}
                    isSelected={selectedVendor?.id === vendor.id}
                    onClick={() => flyToVendor(vendor)}
                  />
                ))}
              </div>
            </div>
          </div>
        ) : (
          /* Grid View */
          <div className="p-4">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm font-medium text-warm-600">
                {sortedVendors.length} contractors found
              </span>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as SortOption)}
                className="text-sm border border-warm-300 rounded-lg px-3 py-1.5 focus:ring-2 focus:ring-haven-500"
              >
                <option value="neighbors">Most Used by Neighbors</option>
                <option value="rating">Highest Rated</option>
                <option value="nearest">Nearest</option>
                <option value="projects">Most Projects</option>
              </select>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {sortedVendors.map(vendor => (
                <VendorCard key={vendor.id} vendor={vendor} />
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ============================================================================
// SUB-COMPONENTS
// ============================================================================

function VendorPopup({ vendor }: { vendor: Vendor }) {
  return (
    <div className="w-[280px] max-w-[280px] overflow-hidden">
      <div className="flex items-start gap-3">
        <img
          src={getVendorAvatar(vendor.name)}
          alt={vendor.name}
          className="w-12 h-12 rounded-lg object-cover flex-shrink-0"
        />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-1.5 flex-wrap">
            <h3 className="font-semibold text-warm-900 truncate max-w-[140px]">{vendor.name}</h3>
            {vendor.havenTrusted && (
              <span className="px-1.5 py-0.5 bg-haven-100 text-haven-700 text-xs font-medium rounded flex-shrink-0">
                Haven Trusted
              </span>
            )}
          </div>
          <div className="flex items-center gap-1.5 text-sm text-warm-500 mt-0.5">
            <Star className="w-3.5 h-3.5 text-amber-500 fill-current flex-shrink-0" />
            <span>{vendor.rating}</span>
            <span className="text-warm-300">•</span>
            <span className="truncate">{vendor.reviewCount} reviews</span>
          </div>
        </div>
      </div>
      <div className="mt-2.5 flex items-center gap-3 text-xs text-warm-600">
        <div className="flex items-center gap-1">
          <Users className="w-3.5 h-3.5 flex-shrink-0" />
          <span>{vendor.neighborsUsed} neighbors</span>
        </div>
        <div className="flex items-center gap-1">
          <MapPin className="w-3.5 h-3.5 flex-shrink-0" />
          <span>{vendor.distance} mi</span>
        </div>
      </div>
      <div className="mt-2.5 flex gap-2">
        <button className="flex-1 px-3 py-1.5 bg-haven-600 text-white text-sm font-medium rounded-lg hover:bg-haven-700 transition-colors">
          Request Quote
        </button>
        <a
          href={`tel:${vendor.phone}`}
          className="px-2.5 py-1.5 border border-warm-300 rounded-lg hover:bg-warm-50 transition-colors flex items-center justify-center"
        >
          <Phone className="w-4 h-4 text-warm-600" />
        </a>
      </div>
    </div>
  );
}

function VendorListItem({
  vendor,
  isSelected,
  onClick
}: {
  vendor: Vendor;
  isSelected: boolean;
  onClick: () => void;
}) {
  return (
    <div
      onClick={onClick}
      className={`p-4 cursor-pointer transition-colors ${
        isSelected ? 'bg-haven-50' : 'hover:bg-warm-50'
      }`}
    >
      <div className="flex gap-3">
        <img
          src={getVendorAvatar(vendor.name)}
          alt={vendor.name}
          className="w-14 h-14 rounded-lg object-cover"
        />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h3 className="font-medium text-warm-900 truncate">{vendor.name}</h3>
            {vendor.havenTrusted && (
              <Shield className="w-4 h-4 text-haven-600 flex-shrink-0" />
            )}
          </div>
          <div className="flex items-center gap-2 text-sm text-warm-500">
            <Star className="w-3.5 h-3.5 text-amber-500 fill-current" />
            <span>{vendor.rating}</span>
            <span>•</span>
            <span>{vendor.priceTier}</span>
            <span>•</span>
            <span>{vendor.distance} mi</span>
          </div>
          <div className="mt-1 flex items-center gap-1 text-xs text-haven-600">
            <Users className="w-3.5 h-3.5" />
            <span>{vendor.neighborsUsed} neighbors used this pro</span>
          </div>
        </div>
      </div>
    </div>
  );
}

function VendorCard({ vendor }: { vendor: Vendor }) {
  const recentProject = vendor.recentProjects[0];

  return (
    <div className="bg-white rounded-xl border border-warm-200 overflow-hidden hover:shadow-lg transition-shadow">
      {/* Cover/Project Image */}
      <div className="relative h-40">
        <img
          src={recentProject?.afterImage || vendor.coverUrl}
          alt={vendor.name}
          className="w-full h-full object-cover"
        />
        {vendor.havenTrusted && (
          <div className="absolute top-2 left-2 px-2 py-1 bg-haven-600 text-white text-xs font-medium rounded-full flex items-center gap-1">
            <Shield className="w-3 h-3" />
            Haven Trusted
          </div>
        )}
        <div className="absolute bottom-2 right-2 px-2 py-1 bg-black/60 text-white text-xs rounded-full">
          {vendor.priceTier}
        </div>
      </div>

      {/* Content */}
      <div className="p-4">
        <div className="flex items-start gap-3">
          <img
            src={getVendorAvatar(vendor.name)}
            alt={vendor.name}
            className="w-12 h-12 rounded-lg object-cover"
          />
          <div className="flex-1">
            <h3 className="font-semibold text-warm-900">{vendor.name}</h3>
            <div className="flex items-center gap-2 text-sm text-warm-500">
              <Star className="w-4 h-4 text-amber-500 fill-current" />
              <span>{vendor.rating}</span>
              <span>({vendor.reviewCount})</span>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="mt-3 grid grid-cols-3 gap-2 text-center">
          <div className="py-2 bg-warm-50 rounded-lg">
            <div className="text-lg font-semibold text-warm-900">{vendor.neighborsUsed}</div>
            <div className="text-xs text-warm-500">Neighbors</div>
          </div>
          <div className="py-2 bg-warm-50 rounded-lg">
            <div className="text-lg font-semibold text-warm-900">{vendor.totalProjects}</div>
            <div className="text-xs text-warm-500">Projects</div>
          </div>
          <div className="py-2 bg-warm-50 rounded-lg">
            <div className="text-lg font-semibold text-warm-900">{vendor.onTimeRate}%</div>
            <div className="text-xs text-warm-500">On Time</div>
          </div>
        </div>

        {/* Specialties */}
        <div className="mt-3 flex flex-wrap gap-1">
          {vendor.specialties.slice(0, 3).map(specialty => (
            <span key={specialty} className="px-2 py-1 bg-warm-100 text-warm-600 text-xs rounded-full">
              {specialty}
            </span>
          ))}
        </div>

        {/* Actions */}
        <div className="mt-4 flex gap-2">
          <button className="flex-1 px-3 py-2 bg-haven-600 text-white text-sm font-medium rounded-lg hover:bg-haven-700">
            Request Quote
          </button>
          <button className="px-3 py-2 border border-warm-300 rounded-lg hover:bg-warm-50">
            <Heart className="w-4 h-4 text-warm-600" />
          </button>
        </div>
      </div>
    </div>
  );
}
