'use client';

import { useState, useRef, useCallback } from 'react';
import Map, { Marker, Popup, NavigationControl } from 'react-map-gl/mapbox';
import type { MapRef } from 'react-map-gl/mapbox';
import 'mapbox-gl/dist/mapbox-gl.css';
import {
  Search,
  MapPin,
  Star,
  Wrench,
  Home,
  Filter,
  ChevronDown,
  ChevronUp,
  X,
  Heart,
  Bookmark,
  MessageCircle,
  Share2,
  Clock,
  CheckCircle2,
  Shield,
  Phone,
  MessageSquare,
  FileText,
  Users,
  TrendingUp,
  Calendar,
  AlertTriangle,
  Sparkles,
  ArrowRight,
  Building2,
  Zap,
  Droplets,
  Paintbrush,
  Hammer,
  TreePine,
  Settings,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type ViewMode = 'feed' | 'directory';
type VendorTrade = 'all' | 'plumber' | 'electrician' | 'landscaper' | 'painter' | 'hvac' | 'general';
type SortOption = 'rating' | 'friends' | 'nearest' | 'recent';
type PriceTier = 'all' | '$' | '$$' | '$$$' | '$$$$';
type PostType = 'project' | 'recommendation' | 'alert' | 'designer';

interface Vendor {
  id: string;
  name: string;
  trade: VendorTrade;
  rating: number;
  reviewCount: number;
  priceTier: PriceTier;
  verified: boolean;
  logoUrl?: string;
  coverUrl?: string;
  location: { lat: number; lng: number };
  address: string;
  distance: number;
  phone: string;
  responseTime: string;
  onTimeRate: number;
  friendsUsed: { id: string; name: string; avatarUrl?: string; lastUsed: string }[];
  projectCount: number;
}

interface Project {
  id: string;
  vendorId: string;
  title: string;
  description: string;
  category: string;
  imageUrls: string[];
  cost: PriceTier;
  completedAt: string;
  location: { lat: number; lng: number };
  homeownerId: string;
  homeownerName: string;
}

interface Review {
  id: string;
  vendorId: string;
  authorName: string;
  authorAvatarUrl?: string;
  rating: number;
  content: string;
  createdAt: string;
  verifiedTransaction: boolean;
  projectType: string;
}

interface FeedPost {
  id: string;
  type: PostType;
  author: {
    id: string;
    name: string;
    avatarUrl?: string;
    isInfluencer?: boolean;
    isNeighbor?: boolean;
  };
  createdAt: string;
  title: string;
  description?: string;
  beforeImages?: string[];
  afterImages?: string[];
  vendor?: Vendor;
  vendors?: Vendor[]; // For designer posts with multiple vendors
  rating?: number;
  cost?: PriceTier;
  likesCount: number;
  savesCount: number;
  commentsCount: number;
  isLiked?: boolean;
  isSaved?: boolean;
  alertType?: 'safety' | 'info';
}

interface TrendingVendor {
  id: string;
  name: string;
  trade: string;
  rating: number;
  bookingsThisWeek: number;
}

interface UpcomingEvent {
  id: string;
  title: string;
  date: string;
  type: 'community' | 'market' | 'class';
}

// ============================================================================
// MOCK DATA
// ============================================================================

const currentUserLocation = { lat: 34.0696, lng: -118.4065 };

const mockVendors: Vendor[] = [
  // TRUSTED VENDORS (Emerald Stars - 4.5+ rating)
  {
    id: 'v1',
    name: 'Mike\'s Plumbing Pro',
    trade: 'plumber',
    rating: 4.9,
    reviewCount: 127,
    priceTier: '$$',
    verified: true,
    logoUrl: '/vendors/mikes-plumbing.jpg',
    coverUrl: '/vendors/mikes-cover.jpg',
    location: { lat: 34.0710, lng: -118.4050 },
    address: '1234 Beverly Blvd, Beverly Hills',
    distance: 0.8,
    phone: '(310) 555-0101',
    responseTime: '2 hours',
    onTimeRate: 95,
    friendsUsed: [
      { id: 'f1', name: 'Alice Chen', lastUsed: '2 weeks ago' },
      { id: 'f2', name: 'Bob Martinez', lastUsed: '1 month ago' },
      { id: 'f3', name: 'Sarah Kim', lastUsed: '3 months ago' },
    ],
    projectCount: 45,
  },
  {
    id: 'v2',
    name: 'Green Leaf Landscaping',
    trade: 'landscaper',
    rating: 4.8,
    reviewCount: 89,
    priceTier: '$$$',
    verified: true,
    location: { lat: 34.0680, lng: -118.4100 },
    address: '567 Garden Way, Beverly Hills',
    distance: 1.2,
    phone: '(310) 555-0202',
    responseTime: '4 hours',
    onTimeRate: 92,
    friendsUsed: [
      { id: 'f1', name: 'Alice Chen', lastUsed: '1 week ago' },
    ],
    projectCount: 32,
  },
  {
    id: 'v5',
    name: 'CoolAir HVAC',
    trade: 'hvac',
    rating: 4.9,
    reviewCount: 41,
    priceTier: '$$$',
    verified: true,
    location: { lat: 34.0700, lng: -118.4120 },
    address: '789 Climate Blvd, Beverly Hills',
    distance: 1.8,
    phone: '(310) 555-0505',
    responseTime: '2 hours',
    onTimeRate: 97,
    friendsUsed: [
      { id: 'f3', name: 'Sarah Kim', lastUsed: '6 months ago' },
    ],
    projectCount: 23,
  },
  {
    id: 'v7',
    name: 'Elite Electric Services',
    trade: 'electrician',
    rating: 4.8,
    reviewCount: 94,
    priceTier: '$$$',
    verified: true,
    location: { lat: 34.0735, lng: -118.4010 },
    address: '555 Volt Ave, Beverly Hills',
    distance: 1.1,
    phone: '(310) 555-0707',
    responseTime: '1 hour',
    onTimeRate: 96,
    friendsUsed: [
      { id: 'f1', name: 'Alice Chen', lastUsed: '3 weeks ago' },
      { id: 'f4', name: 'David Lee', lastUsed: '1 month ago' },
    ],
    projectCount: 56,
  },
  {
    id: 'v8',
    name: 'Premier Pool & Spa',
    trade: 'general',
    rating: 4.7,
    reviewCount: 78,
    priceTier: '$$$$',
    verified: true,
    location: { lat: 34.0650, lng: -118.4030 },
    address: '321 Aqua Ln, Beverly Hills',
    distance: 1.4,
    phone: '(310) 555-0808',
    responseTime: '3 hours',
    onTimeRate: 94,
    friendsUsed: [
      { id: 'f2', name: 'Bob Martinez', lastUsed: '2 weeks ago' },
    ],
    projectCount: 34,
  },
  {
    id: 'v9',
    name: 'Sunshine Painters',
    trade: 'painter',
    rating: 4.6,
    reviewCount: 112,
    priceTier: '$$',
    verified: true,
    location: { lat: 34.0725, lng: -118.4090 },
    address: '888 Color Way, Beverly Hills',
    distance: 0.9,
    phone: '(310) 555-0909',
    responseTime: '2 hours',
    onTimeRate: 91,
    friendsUsed: [
      { id: 'f3', name: 'Sarah Kim', lastUsed: '1 month ago' },
      { id: 'f5', name: 'Emma Wilson', lastUsed: '2 months ago' },
    ],
    projectCount: 89,
  },
  {
    id: 'v10',
    name: 'RoofMasters Pro',
    trade: 'general',
    rating: 4.8,
    reviewCount: 67,
    priceTier: '$$$$',
    verified: true,
    location: { lat: 34.0665, lng: -118.4150 },
    address: '999 Shingle Rd, Beverly Hills',
    distance: 2.0,
    phone: '(310) 555-1010',
    responseTime: '4 hours',
    onTimeRate: 93,
    friendsUsed: [],
    projectCount: 42,
  },
  {
    id: 'v11',
    name: 'AquaFlow Plumbing',
    trade: 'plumber',
    rating: 4.7,
    reviewCount: 83,
    priceTier: '$$$',
    verified: true,
    location: { lat: 34.0740, lng: -118.4070 },
    address: '456 Pipe St, Beverly Hills',
    distance: 1.3,
    phone: '(310) 555-1111',
    responseTime: '2 hours',
    onTimeRate: 89,
    friendsUsed: [
      { id: 'f4', name: 'David Lee', lastUsed: '3 months ago' },
    ],
    projectCount: 51,
  },
  // STANDARD VENDORS (Grey Wrenches - below 4.5 rating)
  {
    id: 'v3',
    name: 'Bright Spark Electric',
    trade: 'electrician',
    rating: 4.3,
    reviewCount: 64,
    priceTier: '$$',
    verified: true,
    location: { lat: 34.0720, lng: -118.4020 },
    address: '890 Power St, Beverly Hills',
    distance: 1.5,
    phone: '(310) 555-0303',
    responseTime: '3 hours',
    onTimeRate: 88,
    friendsUsed: [],
    projectCount: 28,
  },
  {
    id: 'v4',
    name: 'ColorPro Painters',
    trade: 'painter',
    rating: 4.2,
    reviewCount: 52,
    priceTier: '$',
    verified: false,
    location: { lat: 34.0660, lng: -118.4080 },
    address: '432 Canvas Ave, Beverly Hills',
    distance: 0.5,
    phone: '(310) 555-0404',
    responseTime: '1 hour',
    onTimeRate: 90,
    friendsUsed: [
      { id: 'f2', name: 'Bob Martinez', lastUsed: '2 months ago' },
    ],
    projectCount: 67,
  },
  {
    id: 'v6',
    name: 'BuildRight General',
    trade: 'general',
    rating: 4.4,
    reviewCount: 156,
    priceTier: '$$$$',
    verified: true,
    location: { lat: 34.0690, lng: -118.4000 },
    address: '1010 Builder Ln, Beverly Hills',
    distance: 2.1,
    phone: '(310) 555-0606',
    responseTime: '6 hours',
    onTimeRate: 85,
    friendsUsed: [
      { id: 'f1', name: 'Alice Chen', lastUsed: '4 months ago' },
      { id: 'f2', name: 'Bob Martinez', lastUsed: '5 months ago' },
    ],
    projectCount: 89,
  },
  {
    id: 'v12',
    name: 'Budget Lawn Care',
    trade: 'landscaper',
    rating: 4.0,
    reviewCount: 45,
    priceTier: '$',
    verified: false,
    location: { lat: 34.0675, lng: -118.4040 },
    address: '222 Grass Blvd, Beverly Hills',
    distance: 0.7,
    phone: '(310) 555-1212',
    responseTime: '6 hours',
    onTimeRate: 82,
    friendsUsed: [],
    projectCount: 34,
  },
  {
    id: 'v13',
    name: 'Quick Fix Plumbing',
    trade: 'plumber',
    rating: 4.1,
    reviewCount: 38,
    priceTier: '$',
    verified: false,
    location: { lat: 34.0715, lng: -118.4130 },
    address: '777 Drain Ave, Beverly Hills',
    distance: 1.6,
    phone: '(310) 555-1313',
    responseTime: '1 hour',
    onTimeRate: 80,
    friendsUsed: [],
    projectCount: 22,
  },
  {
    id: 'v14',
    name: 'HomeComfort HVAC',
    trade: 'hvac',
    rating: 4.3,
    reviewCount: 29,
    priceTier: '$$',
    verified: true,
    location: { lat: 34.0695, lng: -118.3980 },
    address: '333 Breeze Way, Beverly Hills',
    distance: 2.3,
    phone: '(310) 555-1414',
    responseTime: '4 hours',
    onTimeRate: 86,
    friendsUsed: [
      { id: 'f5', name: 'Emma Wilson', lastUsed: '4 months ago' },
    ],
    projectCount: 18,
  },
  {
    id: 'v15',
    name: 'Valley Electric Co',
    trade: 'electrician',
    rating: 4.0,
    reviewCount: 31,
    priceTier: '$',
    verified: false,
    location: { lat: 34.0755, lng: -118.4060 },
    address: '444 Watt St, Beverly Hills',
    distance: 1.9,
    phone: '(310) 555-1515',
    responseTime: '5 hours',
    onTimeRate: 78,
    friendsUsed: [],
    projectCount: 15,
  },
];

const mockProjects: Project[] = [
  {
    id: 'p1',
    vendorId: 'v1',
    title: 'Kitchen Renovation',
    description: 'Complete kitchen remodel with new plumbing',
    category: 'Plumbing',
    imageUrls: ['/projects/kitchen-1.jpg', '/projects/kitchen-2.jpg'],
    cost: '$$$',
    completedAt: '2024-10-15',
    location: { lat: 34.0705, lng: -118.4055 },
    homeownerId: 'h1',
    homeownerName: 'Alice C.',
  },
  {
    id: 'p2',
    vendorId: 'v2',
    title: 'Backyard Makeover',
    description: 'Full landscape redesign with drought-resistant plants',
    category: 'Landscaping',
    imageUrls: ['/projects/backyard-1.jpg'],
    cost: '$$$$',
    completedAt: '2024-09-20',
    location: { lat: 34.0685, lng: -118.4090 },
    homeownerId: 'h2',
    homeownerName: 'Bob M.',
  },
  {
    id: 'p3',
    vendorId: 'v4',
    title: 'Living Room Repaint',
    description: 'Accent wall and trim refresh',
    category: 'Painting',
    imageUrls: ['/projects/living-1.jpg'],
    cost: '$',
    completedAt: '2024-11-01',
    location: { lat: 34.0670, lng: -118.4070 },
    homeownerId: 'h3',
    homeownerName: 'Sarah K.',
  },
  {
    id: 'p4',
    vendorId: 'v7',
    title: 'Smart Home Wiring',
    description: 'Complete electrical upgrade with smart switches and outlets',
    category: 'Electrical',
    imageUrls: ['/projects/smart-home-1.jpg'],
    cost: '$$$$',
    completedAt: '2024-11-10',
    location: { lat: 34.0730, lng: -118.4025 },
    homeownerId: 'h4',
    homeownerName: 'David L.',
  },
  {
    id: 'p5',
    vendorId: 'v5',
    title: 'HVAC System Replacement',
    description: 'Full AC and heating system upgrade to energy-efficient units',
    category: 'HVAC',
    imageUrls: ['/projects/hvac-1.jpg'],
    cost: '$$$$',
    completedAt: '2024-10-28',
    location: { lat: 34.0658, lng: -118.4115 },
    homeownerId: 'h5',
    homeownerName: 'Emma W.',
  },
  {
    id: 'p6',
    vendorId: 'v8',
    title: 'Pool Renovation',
    description: 'Resurfaced pool with new tile and lighting',
    category: 'Pool & Spa',
    imageUrls: ['/projects/pool-1.jpg', '/projects/pool-2.jpg'],
    cost: '$$$$',
    completedAt: '2024-09-05',
    location: { lat: 34.0645, lng: -118.4045 },
    homeownerId: 'h6',
    homeownerName: 'Michael R.',
  },
  {
    id: 'p7',
    vendorId: 'v9',
    title: 'Exterior House Painting',
    description: 'Complete exterior repaint with premium materials',
    category: 'Painting',
    imageUrls: ['/projects/exterior-1.jpg'],
    cost: '$$$',
    completedAt: '2024-11-05',
    location: { lat: 34.0718, lng: -118.4105 },
    homeownerId: 'h7',
    homeownerName: 'Jennifer T.',
  },
  {
    id: 'p8',
    vendorId: 'v10',
    title: 'Roof Replacement',
    description: 'Complete roof replacement with 30-year warranty shingles',
    category: 'Roofing',
    imageUrls: ['/projects/roof-1.jpg'],
    cost: '$$$$',
    completedAt: '2024-08-20',
    location: { lat: 34.0695, lng: -118.3995 },
    homeownerId: 'h8',
    homeownerName: 'Chris M.',
  },
  {
    id: 'p9',
    vendorId: 'v11',
    title: 'Master Bath Remodel',
    description: 'Luxury bathroom renovation with walk-in shower',
    category: 'Plumbing',
    imageUrls: ['/projects/bathroom-1.jpg', '/projects/bathroom-2.jpg'],
    cost: '$$$$',
    completedAt: '2024-10-01',
    location: { lat: 34.0748, lng: -118.4080 },
    homeownerId: 'h9',
    homeownerName: 'Lisa K.',
  },
  {
    id: 'p10',
    vendorId: 'v2',
    title: 'Front Yard Redesign',
    description: 'California native plants with water-efficient irrigation',
    category: 'Landscaping',
    imageUrls: ['/projects/frontyard-1.jpg'],
    cost: '$$$',
    completedAt: '2024-11-12',
    location: { lat: 34.0672, lng: -118.4135 },
    homeownerId: 'h10',
    homeownerName: 'Tom B.',
  },
];

const mockReviews: Review[] = [
  {
    id: 'r1',
    vendorId: 'v1',
    authorName: 'Alice Chen',
    rating: 5,
    content: 'Mike and his team were incredible! They fixed our kitchen plumbing issue in no time and even identified a potential problem we didn\'t know about. Highly recommend!',
    createdAt: '2024-10-20',
    verifiedTransaction: true,
    projectType: 'Kitchen Plumbing',
  },
  {
    id: 'r2',
    vendorId: 'v1',
    authorName: 'Bob Martinez',
    rating: 5,
    content: 'Professional, on time, and fair pricing. They\'ve earned a customer for life.',
    createdAt: '2024-09-15',
    verifiedTransaction: true,
    projectType: 'Bathroom Remodel',
  },
  {
    id: 'r3',
    vendorId: 'v1',
    authorName: 'Carol Davis',
    rating: 4,
    content: 'Good work overall, minor scheduling delay but they communicated well.',
    createdAt: '2024-08-10',
    verifiedTransaction: false,
    projectType: 'Pipe Repair',
  },
];

const mockFeedPosts: FeedPost[] = [
  {
    id: 'post1',
    type: 'recommendation',
    author: { id: 'u1', name: 'Sarah Kim', isNeighbor: true },
    createdAt: '2024-11-15T10:30:00',
    title: 'Just recommended Green Leaf Landscaping',
    description: 'for "Spring Cleanup" ($)',
    vendor: mockVendors[1],
    rating: 5,
    cost: '$',
    likesCount: 12,
    savesCount: 5,
    commentsCount: 3,
  },
  {
    id: 'post2',
    type: 'project',
    author: { id: 'u2', name: 'Alice Chen', isNeighbor: true },
    createdAt: '2024-11-14T14:00:00',
    title: 'Kitchen Transformation Complete!',
    description: 'After 3 weeks, our kitchen is finally done. Mike\'s Plumbing did an amazing job with the sink and dishwasher installation.',
    beforeImages: ['/projects/kitchen-before.jpg'],
    afterImages: ['/projects/kitchen-after.jpg'],
    vendor: mockVendors[0],
    cost: '$$$',
    likesCount: 45,
    savesCount: 18,
    commentsCount: 12,
  },
  {
    id: 'post3',
    type: 'alert',
    author: { id: 'admin', name: 'Haven Community' },
    createdAt: '2024-11-15T08:00:00',
    title: 'Road Closure Alert',
    description: 'Beverly Drive will be closed from 9 AM - 5 PM today for utility work. Plan alternate routes.',
    alertType: 'info',
    likesCount: 8,
    savesCount: 2,
    commentsCount: 4,
  },
  {
    id: 'post4',
    type: 'designer',
    author: { id: 'u3', name: 'Modern Home Designs', isInfluencer: true },
    createdAt: '2024-11-13T16:00:00',
    title: 'Scandinavian Living Room Reveal',
    description: 'Clean lines, natural materials, and that perfect cozy feel. Here\'s the team that made it happen.',
    afterImages: ['/projects/scandinavian-living.jpg'],
    vendors: [mockVendors[3], mockVendors[5]],
    likesCount: 234,
    savesCount: 89,
    commentsCount: 28,
  },
  {
    id: 'post5',
    type: 'project',
    author: { id: 'u4', name: 'Bob Martinez', isNeighbor: true },
    createdAt: '2024-11-12T11:00:00',
    title: 'New Backyard Oasis',
    description: 'Green Leaf Landscaping transformed our backyard into the perfect outdoor retreat.',
    beforeImages: ['/projects/yard-before.jpg'],
    afterImages: ['/projects/yard-after.jpg'],
    vendor: mockVendors[1],
    cost: '$$$$',
    likesCount: 67,
    savesCount: 34,
    commentsCount: 15,
  },
];

const mockTrendingVendors: TrendingVendor[] = [
  { id: 'v1', name: 'Mike\'s Plumbing Pro', trade: 'Plumber', rating: 4.9, bookingsThisWeek: 12 },
  { id: 'v2', name: 'Green Leaf Landscaping', trade: 'Landscaper', rating: 4.8, bookingsThisWeek: 8 },
  { id: 'v5', name: 'CoolAir HVAC', trade: 'HVAC', rating: 4.9, bookingsThisWeek: 6 },
];

const mockUpcomingEvents: UpcomingEvent[] = [
  { id: 'e1', title: 'Neighborhood Block Party', date: '2024-11-23', type: 'community' },
  { id: 'e2', title: 'Home Maintenance Workshop', date: '2024-11-30', type: 'class' },
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function formatRelativeTime(dateString: string): string {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function getTradeIcon(trade: VendorTrade) {
  const icons: Record<VendorTrade, typeof Wrench> = {
    all: Settings,
    plumber: Droplets,
    electrician: Zap,
    landscaper: TreePine,
    painter: Paintbrush,
    hvac: Settings,
    general: Hammer,
  };
  return icons[trade] || Wrench;
}

function getTradeLabel(trade: VendorTrade): string {
  const labels: Record<VendorTrade, string> = {
    all: 'All Trades',
    plumber: 'Plumber',
    electrician: 'Electrician',
    landscaper: 'Landscaper',
    painter: 'Painter',
    hvac: 'HVAC',
    general: 'General Contractor',
  };
  return labels[trade];
}

// ============================================================================
// COMPONENTS
// ============================================================================

// View Mode Toggle
function ViewModeToggle({ mode, onChange }: { mode: ViewMode; onChange: (mode: ViewMode) => void }) {
  return (
    <div className="flex bg-slate-100 rounded-lg p-1">
      <button
        onClick={() => onChange('feed')}
        className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-all ${
          mode === 'feed'
            ? 'bg-white text-slate-900 shadow-sm'
            : 'text-slate-600 hover:text-slate-900'
        }`}
      >
        <Sparkles className="w-4 h-4" />
        Feed
      </button>
      <button
        onClick={() => onChange('directory')}
        className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-all ${
          mode === 'directory'
            ? 'bg-white text-slate-900 shadow-sm'
            : 'text-slate-600 hover:text-slate-900'
        }`}
      >
        <Building2 className="w-4 h-4" />
        Directory
      </button>
    </div>
  );
}

// Search Bar for Directory
function DirectorySearchBar({
  searchQuery,
  onSearch,
  selectedTrade,
  onTradeChange,
}: {
  searchQuery: string;
  onSearch: (query: string) => void;
  selectedTrade: VendorTrade;
  onTradeChange: (trade: VendorTrade) => void;
}) {
  const trades: VendorTrade[] = ['all', 'plumber', 'electrician', 'landscaper', 'painter', 'hvac', 'general'];

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 mb-4">
      <div className="flex items-center gap-3">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => onSearch(e.target.value)}
            placeholder="Find a plumber, electrician, landscaper..."
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border-0 rounded-lg text-sm focus:ring-2 focus:ring-emerald-600 focus:bg-white transition-colors"
          />
        </div>
      </div>

      {/* Trade Pills */}
      <div className="flex flex-wrap gap-2 mt-3">
        {trades.map((trade) => {
          const Icon = getTradeIcon(trade);
          return (
            <button
              key={trade}
              onClick={() => onTradeChange(trade)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium transition-all ${
                selectedTrade === trade
                  ? 'bg-emerald-600 text-white'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              <Icon className="w-3.5 h-3.5" />
              {getTradeLabel(trade)}
            </button>
          );
        })}
      </div>
    </div>
  );
}

// Filter Bar
function FilterBar({
  sortBy,
  onSortChange,
  priceTier,
  onPriceChange,
}: {
  sortBy: SortOption;
  onSortChange: (sort: SortOption) => void;
  priceTier: PriceTier;
  onPriceChange: (price: PriceTier) => void;
}) {
  return (
    <div className="flex items-center gap-4 mb-4">
      <div className="flex items-center gap-2">
        <Filter className="w-4 h-4 text-slate-500" />
        <select
          value={sortBy}
          onChange={(e) => onSortChange(e.target.value as SortOption)}
          className="text-sm border-0 bg-transparent text-slate-700 font-medium focus:ring-0 cursor-pointer"
        >
          <option value="rating">Highest Rated</option>
          <option value="friends">Most Used by Friends</option>
          <option value="nearest">Nearest</option>
          <option value="recent">Recently Active</option>
        </select>
      </div>

      <div className="flex items-center gap-1">
        {(['all', '$', '$$', '$$$', '$$$$'] as PriceTier[]).map((tier) => (
          <button
            key={tier}
            onClick={() => onPriceChange(tier)}
            className={`px-2 py-1 text-sm font-medium rounded transition-colors ${
              priceTier === tier
                ? 'bg-emerald-100 text-emerald-700'
                : 'text-slate-500 hover:text-slate-700'
            }`}
          >
            {tier === 'all' ? 'All' : tier}
          </button>
        ))}
      </div>
    </div>
  );
}

// Vendor Card in List
function VendorCard({
  vendor,
  isHovered,
  onHover,
  onClick,
}: {
  vendor: Vendor;
  isHovered: boolean;
  onHover: (id: string | null) => void;
  onClick: () => void;
}) {
  const TradeIcon = getTradeIcon(vendor.trade);

  return (
    <div
      onClick={onClick}
      onMouseEnter={() => onHover(vendor.id)}
      onMouseLeave={() => onHover(null)}
      className={`bg-white rounded-xl shadow-sm border p-4 cursor-pointer transition-all ${
        isHovered
          ? 'border-emerald-400 shadow-md ring-1 ring-emerald-400'
          : 'border-slate-200 hover:border-slate-300'
      }`}
    >
      <div className="flex items-start gap-3">
        {/* Logo */}
        <div className="w-14 h-14 rounded-xl bg-slate-100 flex items-center justify-center flex-shrink-0">
          <TradeIcon className="w-6 h-6 text-slate-500" />
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h3 className="font-semibold text-slate-900 truncate">{vendor.name}</h3>
            {vendor.verified && (
              <Shield className="w-4 h-4 text-amber-500 flex-shrink-0" />
            )}
          </div>

          {/* Rating */}
          <div className="flex items-center gap-2 mt-1">
            <div className="flex items-center gap-1">
              <Star className="w-4 h-4 text-amber-400 fill-amber-400" />
              <span className="font-semibold text-slate-900">{vendor.rating}</span>
              <span className="text-slate-500 text-sm">({vendor.reviewCount})</span>
            </div>
            <span className="text-slate-300">·</span>
            <span className="text-slate-500 text-sm">{vendor.distance} mi</span>
            <span className="text-slate-300">·</span>
            <span className="text-emerald-600 font-medium">{vendor.priceTier}</span>
          </div>

          {/* Social Proof */}
          {vendor.friendsUsed.length > 0 && (
            <div className="flex items-center gap-2 mt-2 text-sm text-slate-600">
              <Users className="w-4 h-4 text-emerald-600" />
              <span>
                Last used by <span className="font-medium">{vendor.friendsUsed[0].name}</span>{' '}
                {vendor.friendsUsed[0].lastUsed}
              </span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// Map Pin Components
function VendorPin({ vendor, isHovered }: { vendor: Vendor; isHovered: boolean }) {
  const isTrusted = vendor.rating >= 4.5;

  return (
    <div
      className={`relative cursor-pointer transition-transform ${
        isHovered ? 'scale-125 z-10' : ''
      }`}
    >
      <div
        className={`w-10 h-10 rounded-full flex items-center justify-center shadow-lg ${
          isTrusted
            ? 'bg-emerald-600 text-white'
            : 'bg-white text-slate-600 border-2 border-slate-300'
        }`}
      >
        {isTrusted ? (
          <Star className="w-5 h-5 fill-white" />
        ) : (
          <Wrench className="w-5 h-5" />
        )}
      </div>
      {isHovered && (
        <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-t-4 border-l-transparent border-r-transparent border-t-emerald-600" />
      )}
    </div>
  );
}

function ProjectPin({ project }: { project: Project }) {
  return (
    <div className="w-8 h-8 rounded-full bg-blue-500 text-white flex items-center justify-center shadow-lg cursor-pointer hover:scale-110 transition-transform">
      <Home className="w-4 h-4" />
    </div>
  );
}

// Vendor Profile Modal
function VendorProfileModal({
  vendor,
  onClose,
}: {
  vendor: Vendor;
  onClose: () => void;
}) {
  const [activeTab, setActiveTab] = useState<'portfolio' | 'reputation' | 'stats'>('portfolio');
  const TradeIcon = getTradeIcon(vendor.trade);

  const vendorProjects = mockProjects.filter((p) => p.vendorId === vendor.id);
  const vendorReviews = mockReviews.filter((r) => r.vendorId === vendor.id);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 z-10 p-2 bg-black/20 hover:bg-black/30 rounded-full text-white transition-colors"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Cover Image */}
        <div className="h-40 bg-gradient-to-br from-slate-700 to-slate-900 relative">
          <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
        </div>

        {/* Header */}
        <div className="px-6 -mt-12 relative">
          <div className="flex items-end gap-4">
            <div className="w-24 h-24 rounded-2xl bg-white shadow-lg flex items-center justify-center border-4 border-white">
              <TradeIcon className="w-10 h-10 text-slate-600" />
            </div>
            <div className="flex-1 pb-2">
              <div className="flex items-center gap-2">
                <h2 className="text-2xl font-bold text-slate-900">{vendor.name}</h2>
                {vendor.verified && (
                  <div className="flex items-center gap-1 px-2 py-0.5 bg-amber-100 rounded-full">
                    <Shield className="w-4 h-4 text-amber-600" />
                    <span className="text-xs font-medium text-amber-700">Verified</span>
                  </div>
                )}
              </div>
              <div className="flex items-center gap-3 mt-1">
                <div className="flex items-center gap-1">
                  <Star className="w-5 h-5 text-amber-400 fill-amber-400" />
                  <span className="font-bold text-lg">{vendor.rating}</span>
                  <span className="text-slate-500">({vendor.reviewCount} reviews)</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-slate-200 px-6 mt-4">
          {(['portfolio', 'reputation', 'stats'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-3 text-sm font-medium border-b-2 -mb-px transition-colors ${
                activeTab === tab
                  ? 'border-emerald-600 text-emerald-600'
                  : 'border-transparent text-slate-500 hover:text-slate-700'
              }`}
            >
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {activeTab === 'portfolio' && (
            <div className="space-y-4">
              {vendorProjects.length > 0 ? (
                <div className="grid grid-cols-2 gap-4">
                  {vendorProjects.map((project) => (
                    <div
                      key={project.id}
                      className="rounded-xl overflow-hidden bg-slate-100 aspect-square relative group cursor-pointer"
                    >
                      <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                      <div className="absolute bottom-0 left-0 right-0 p-3 text-white opacity-0 group-hover:opacity-100 transition-opacity">
                        <p className="font-medium">{project.title}</p>
                        <p className="text-sm text-white/80">{project.completedAt} · {project.cost}</p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8 text-slate-500">
                  <FileText className="w-12 h-12 mx-auto mb-2 text-slate-300" />
                  <p>No portfolio projects yet</p>
                </div>
              )}
            </div>
          )}

          {activeTab === 'reputation' && (
            <div className="space-y-4">
              {/* Friends who used */}
              {vendor.friendsUsed.length > 0 && (
                <div className="bg-emerald-50 rounded-xl p-4 mb-6">
                  <div className="flex items-center gap-2 mb-3">
                    <Users className="w-5 h-5 text-emerald-600" />
                    <span className="font-medium text-emerald-900">
                      {vendor.friendsUsed.length} of your neighbors have used this vendor
                    </span>
                  </div>
                  <div className="flex -space-x-2">
                    {vendor.friendsUsed.map((friend) => (
                      <div
                        key={friend.id}
                        className="w-8 h-8 rounded-full bg-slate-300 border-2 border-white flex items-center justify-center text-xs font-medium"
                        title={friend.name}
                      >
                        {friend.name[0]}
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Reviews */}
              <div className="space-y-4">
                {vendorReviews.map((review) => (
                  <div key={review.id} className="border-b border-slate-100 pb-4 last:border-0">
                    <div className="flex items-start gap-3">
                      <div className="w-10 h-10 rounded-full bg-slate-200 flex items-center justify-center text-sm font-medium">
                        {review.authorName[0]}
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-slate-900">{review.authorName}</span>
                          {review.verifiedTransaction && (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs rounded-full">
                              <CheckCircle2 className="w-3 h-3" />
                              Verified Client
                            </span>
                          )}
                        </div>
                        <div className="flex items-center gap-2 mt-1">
                          <div className="flex">
                            {[...Array(5)].map((_, i) => (
                              <Star
                                key={i}
                                className={`w-4 h-4 ${
                                  i < review.rating
                                    ? 'text-amber-400 fill-amber-400'
                                    : 'text-slate-200'
                                }`}
                              />
                            ))}
                          </div>
                          <span className="text-sm text-slate-500">{review.projectType}</span>
                        </div>
                        <p className="text-slate-600 mt-2">{review.content}</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeTab === 'stats' && (
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-slate-50 rounded-xl p-4">
                <div className="flex items-center gap-2 text-slate-500 mb-1">
                  <Clock className="w-4 h-4" />
                  <span className="text-sm">Response Time</span>
                </div>
                <p className="text-2xl font-bold text-slate-900">Avg. {vendor.responseTime}</p>
              </div>
              <div className="bg-slate-50 rounded-xl p-4">
                <div className="flex items-center gap-2 text-slate-500 mb-1">
                  <CheckCircle2 className="w-4 h-4" />
                  <span className="text-sm">On-Time Rate</span>
                </div>
                <p className="text-2xl font-bold text-emerald-600">{vendor.onTimeRate}%</p>
              </div>
              <div className="bg-slate-50 rounded-xl p-4">
                <div className="flex items-center gap-2 text-slate-500 mb-1">
                  <FileText className="w-4 h-4" />
                  <span className="text-sm">Projects Completed</span>
                </div>
                <p className="text-2xl font-bold text-slate-900">{vendor.projectCount}</p>
              </div>
              <div className="bg-slate-50 rounded-xl p-4">
                <div className="flex items-center gap-2 text-slate-500 mb-1">
                  <TrendingUp className="w-4 h-4" />
                  <span className="text-sm">Price Range</span>
                </div>
                <p className="text-2xl font-bold text-slate-900">{vendor.priceTier}</p>
              </div>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <div className="border-t border-slate-200 p-4 flex gap-3">
          <a
            href={`tel:${vendor.phone}`}
            className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-white border border-slate-200 rounded-lg font-medium text-slate-700 hover:bg-slate-50 transition-colors"
          >
            <Phone className="w-4 h-4" />
            Call
          </a>
          <button className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-white border border-slate-200 rounded-lg font-medium text-slate-700 hover:bg-slate-50 transition-colors">
            <MessageSquare className="w-4 h-4" />
            Message
          </button>
          <button className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-emerald-600 rounded-lg font-medium text-white hover:bg-emerald-700 transition-colors">
            <FileText className="w-4 h-4" />
            Request Quote
          </button>
        </div>
      </div>
    </div>
  );
}

// Feed Post Card
function FeedPostCard({
  post,
  onLike,
  onSave,
  onVendorClick,
}: {
  post: FeedPost;
  onLike: (id: string) => void;
  onSave: (id: string) => void;
  onVendorClick: (vendor: Vendor) => void;
}) {
  const [sliderPosition, setSliderPosition] = useState(50);
  const hasBeforeAfter = post.beforeImages?.length && post.afterImages?.length;

  const isAlert = post.type === 'alert';
  const isRecommendation = post.type === 'recommendation';
  const isDesigner = post.type === 'designer';

  return (
    <div
      className={`bg-white rounded-xl shadow-sm border overflow-hidden ${
        isAlert && post.alertType === 'safety'
          ? 'border-red-300 bg-red-50'
          : isAlert
          ? 'border-amber-300 bg-amber-50'
          : 'border-slate-200'
      }`}
    >
      {/* Header */}
      <div className="flex items-center gap-3 p-4">
        <div className="w-10 h-10 rounded-full bg-slate-200 flex items-center justify-center text-sm font-medium overflow-hidden">
          {isAlert ? (
            <AlertTriangle className={`w-5 h-5 ${post.alertType === 'safety' ? 'text-red-500' : 'text-amber-500'}`} />
          ) : (
            post.author.name[0]
          )}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="font-medium text-slate-900">{post.author.name}</span>
            {post.author.isInfluencer && (
              <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-purple-100 text-purple-700 text-xs font-medium rounded-full">
                <Star className="w-3 h-3 fill-purple-500 text-purple-500" />
                Designer
              </span>
            )}
            {post.author.isNeighbor && (
              <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                <MapPin className="w-3 h-3" />
                Neighbor
              </span>
            )}
          </div>
          <p className="text-sm text-slate-500">{formatRelativeTime(post.createdAt)}</p>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 pb-3">
        <h3 className="font-semibold text-lg text-slate-900">{post.title}</h3>
        {post.description && (
          <p className="text-slate-600 mt-1">{post.description}</p>
        )}
      </div>

      {/* Before/After Slider */}
      {hasBeforeAfter && (
        <div className="relative aspect-video bg-slate-100 overflow-hidden">
          <div className="absolute inset-0">
            <div className="w-full h-full bg-slate-200" />
          </div>
          <div
            className="absolute inset-y-0 left-0 overflow-hidden"
            style={{ width: `${sliderPosition}%` }}
          >
            <div className="w-full h-full bg-slate-300" />
          </div>
          {/* Slider Handle */}
          <div
            className="absolute inset-y-0 cursor-ew-resize"
            style={{ left: `${sliderPosition}%`, transform: 'translateX(-50%)' }}
          >
            <div className="w-1 h-full bg-white shadow-lg" />
            <div className="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center">
              <ArrowRight className="w-4 h-4 text-slate-600 rotate-180" />
              <ArrowRight className="w-4 h-4 text-slate-600" />
            </div>
          </div>
          {/* Labels */}
          <span className="absolute top-2 left-2 px-2 py-1 bg-black/60 text-white text-xs rounded">Before</span>
          <span className="absolute top-2 right-2 px-2 py-1 bg-black/60 text-white text-xs rounded">After</span>
          {/* Drag Handler */}
          <input
            type="range"
            min="0"
            max="100"
            value={sliderPosition}
            onChange={(e) => setSliderPosition(Number(e.target.value))}
            className="absolute inset-0 w-full h-full opacity-0 cursor-ew-resize"
          />
        </div>
      )}

      {/* Single Image */}
      {!hasBeforeAfter && post.afterImages?.length && (
        <div className="aspect-video bg-slate-100" />
      )}

      {/* Vendor Tags */}
      {(post.vendor || post.vendors?.length) && (
        <div className="px-4 py-3 border-t border-slate-100">
          {isDesigner && (
            <p className="text-xs text-slate-500 mb-2 font-medium uppercase tracking-wide">Get the Team</p>
          )}
          <div className="flex flex-wrap gap-2">
            {post.vendor && (
              <button
                onClick={() => onVendorClick(post.vendor!)}
                className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 rounded-full text-sm font-medium transition-colors"
              >
                <Building2 className="w-4 h-4" />
                {post.vendor.name}
                <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                {post.vendor.rating}
              </button>
            )}
            {post.vendors?.map((v) => (
              <button
                key={v.id}
                onClick={() => onVendorClick(v)}
                className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 rounded-full text-sm font-medium transition-colors"
              >
                <Building2 className="w-4 h-4" />
                {v.name}
              </button>
            ))}
            {post.cost && (
              <span className="inline-flex items-center px-3 py-1.5 bg-slate-100 text-slate-600 rounded-full text-sm font-medium">
                {post.cost}
              </span>
            )}
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="px-4 py-3 border-t border-slate-100 flex items-center gap-4">
        <button
          onClick={() => onLike(post.id)}
          className={`flex items-center gap-1.5 text-sm ${
            post.isLiked ? 'text-red-500' : 'text-slate-500 hover:text-red-500'
          }`}
        >
          <Heart className={`w-5 h-5 ${post.isLiked ? 'fill-current' : ''}`} />
          <span>{post.likesCount}</span>
        </button>
        <button
          onClick={() => onSave(post.id)}
          className={`flex items-center gap-1.5 text-sm ${
            post.isSaved ? 'text-emerald-500' : 'text-slate-500 hover:text-emerald-500'
          }`}
        >
          <Bookmark className={`w-5 h-5 ${post.isSaved ? 'fill-current' : ''}`} />
          <span>{post.savesCount}</span>
        </button>
        <button className="flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700">
          <MessageCircle className="w-5 h-5" />
          <span>{post.commentsCount}</span>
        </button>
        <button className="ml-auto text-slate-500 hover:text-slate-700">
          <Share2 className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}

// Trending Sidebar
function TrendingSidebar({
  trendingVendors,
  upcomingEvents,
  onVendorClick,
}: {
  trendingVendors: TrendingVendor[];
  upcomingEvents: UpcomingEvent[];
  onVendorClick: (id: string) => void;
}) {
  return (
    <div className="space-y-6">
      {/* Trending Vendors */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
        <h3 className="font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <TrendingUp className="w-4 h-4 text-emerald-600" />
          Trending This Week
        </h3>
        <div className="space-y-3">
          {trendingVendors.map((vendor, idx) => (
            <button
              key={vendor.id}
              onClick={() => onVendorClick(vendor.id)}
              className="w-full flex items-center gap-3 p-2 rounded-lg hover:bg-slate-50 transition-colors text-left"
            >
              <span className="w-6 h-6 rounded-full bg-emerald-100 text-emerald-700 flex items-center justify-center text-xs font-bold">
                {idx + 1}
              </span>
              <div className="flex-1 min-w-0">
                <p className="font-medium text-slate-900 truncate">{vendor.name}</p>
                <p className="text-sm text-slate-500">{vendor.trade}</p>
              </div>
              <div className="text-right">
                <div className="flex items-center gap-1 text-amber-500">
                  <Star className="w-3 h-3 fill-current" />
                  <span className="text-sm font-medium">{vendor.rating}</span>
                </div>
                <p className="text-xs text-slate-400">{vendor.bookingsThisWeek} bookings</p>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Upcoming Events */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
        <h3 className="font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <Calendar className="w-4 h-4 text-emerald-600" />
          Upcoming Events
        </h3>
        <div className="space-y-3">
          {upcomingEvents.map((event) => (
            <div key={event.id} className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-lg bg-slate-100 flex flex-col items-center justify-center">
                <span className="text-xs text-slate-500">
                  {new Date(event.date).toLocaleDateString('en-US', { month: 'short' })}
                </span>
                <span className="text-sm font-bold text-slate-900">
                  {new Date(event.date).getDate()}
                </span>
              </div>
              <div>
                <p className="font-medium text-slate-900">{event.title}</p>
                <span className="text-xs text-emerald-600 capitalize">{event.type}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// Mobile Bottom Drawer for Directory
function MobileDirectoryDrawer({
  vendors,
  selectedVendor,
  onVendorSelect,
  isExpanded,
  onToggle,
}: {
  vendors: Vendor[];
  selectedVendor: string | null;
  onVendorSelect: (vendor: Vendor) => void;
  isExpanded: boolean;
  onToggle: () => void;
}) {
  return (
    <div
      className={`lg:hidden fixed bottom-0 left-0 right-0 bg-white rounded-t-2xl shadow-2xl border-t border-slate-200 transition-all z-40 ${
        isExpanded ? 'h-[75vh]' : 'h-[25vh]'
      }`}
    >
      {/* Handle */}
      <button
        onClick={onToggle}
        className="w-full flex justify-center py-2"
      >
        <div className="w-10 h-1 bg-slate-300 rounded-full" />
      </button>

      {/* Header */}
      <div className="px-4 pb-2 flex items-center justify-between">
        <span className="font-semibold text-slate-900">{vendors.length} Vendors</span>
        <button onClick={onToggle}>
          {isExpanded ? (
            <ChevronDown className="w-5 h-5 text-slate-500" />
          ) : (
            <ChevronUp className="w-5 h-5 text-slate-500" />
          )}
        </button>
      </div>

      {/* List */}
      <div className="overflow-y-auto px-4 pb-20" style={{ height: 'calc(100% - 60px)' }}>
        <div className="space-y-3">
          {vendors.map((vendor) => (
            <VendorCard
              key={vendor.id}
              vendor={vendor}
              isHovered={selectedVendor === vendor.id}
              onHover={() => {}}
              onClick={() => onVendorSelect(vendor)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function CommunityPage() {
  const [viewMode, setViewMode] = useState<ViewMode>('feed');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedTrade, setSelectedTrade] = useState<VendorTrade>('all');
  const [sortBy, setSortBy] = useState<SortOption>('rating');
  const [priceTier, setPriceTier] = useState<PriceTier>('all');
  const [hoveredVendor, setHoveredVendor] = useState<string | null>(null);
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);
  const [mobileDrawerExpanded, setMobileDrawerExpanded] = useState(false);
  const [mapMoved, setMapMoved] = useState(false);
  const [posts, setPosts] = useState(mockFeedPosts);
  const [popupProject, setPopupProject] = useState<Project | null>(null);

  const mapRef = useRef<MapRef>(null);

  // Filter vendors
  const filteredVendors = mockVendors.filter((vendor) => {
    if (selectedTrade !== 'all' && vendor.trade !== selectedTrade) return false;
    if (priceTier !== 'all' && vendor.priceTier !== priceTier) return false;
    if (searchQuery && !vendor.name.toLowerCase().includes(searchQuery.toLowerCase())) return false;
    return true;
  });

  // Sort vendors
  const sortedVendors = [...filteredVendors].sort((a, b) => {
    switch (sortBy) {
      case 'rating':
        return b.rating - a.rating;
      case 'friends':
        return b.friendsUsed.length - a.friendsUsed.length;
      case 'nearest':
        return a.distance - b.distance;
      default:
        return 0;
    }
  });

  // Handle map move
  const handleMapMove = useCallback(() => {
    setMapMoved(true);
  }, []);

  // Reset map to user location
  const handleSearchThisArea = () => {
    setMapMoved(false);
    mapRef.current?.flyTo({
      center: [currentUserLocation.lng, currentUserLocation.lat],
      zoom: 14,
    });
  };

  // Handle like/save
  const handleLike = (postId: string) => {
    setPosts(posts.map(p =>
      p.id === postId ? { ...p, isLiked: !p.isLiked, likesCount: p.likesCount + (p.isLiked ? -1 : 1) } : p
    ));
  };

  const handleSave = (postId: string) => {
    setPosts(posts.map(p =>
      p.id === postId ? { ...p, isSaved: !p.isSaved, savesCount: p.savesCount + (p.isSaved ? -1 : 1) } : p
    ));
  };

  const handleVendorClick = (vendor: Vendor) => {
    setSelectedVendor(vendor);
  };

  const handleTrendingVendorClick = (vendorId: string) => {
    const vendor = mockVendors.find(v => v.id === vendorId);
    if (vendor) setSelectedVendor(vendor);
  };

  return (
    <div className="pb-32 lg:pb-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl lg:text-3xl font-bold text-slate-900">Community</h1>
          <p className="text-slate-500">Discover trusted vendors and neighborhood projects</p>
        </div>
        <ViewModeToggle mode={viewMode} onChange={setViewMode} />
      </div>

      {/* Directory Mode */}
      {viewMode === 'directory' && (
        <>
          <DirectorySearchBar
            searchQuery={searchQuery}
            onSearch={setSearchQuery}
            selectedTrade={selectedTrade}
            onTradeChange={setSelectedTrade}
          />

          <FilterBar
            sortBy={sortBy}
            onSortChange={setSortBy}
            priceTier={priceTier}
            onPriceChange={setPriceTier}
          />

          {/* Desktop Split View */}
          <div className="hidden lg:flex gap-6 h-[calc(100vh-300px)] min-h-[500px]">
            {/* Vendor List */}
            <div className="w-[400px] overflow-y-auto pr-2 space-y-4">
              {sortedVendors.map((vendor) => (
                <VendorCard
                  key={vendor.id}
                  vendor={vendor}
                  isHovered={hoveredVendor === vendor.id}
                  onHover={setHoveredVendor}
                  onClick={() => handleVendorClick(vendor)}
                />
              ))}
              {sortedVendors.length === 0 && (
                <div className="text-center py-12 text-slate-500">
                  <Search className="w-12 h-12 mx-auto mb-3 text-slate-300" />
                  <p className="font-medium">No vendors found</p>
                  <p className="text-sm">Try adjusting your filters</p>
                </div>
              )}
            </div>

            {/* Map */}
            <div className="flex-1 rounded-xl overflow-hidden border border-slate-200 relative">
              <Map
                ref={mapRef}
                initialViewState={{
                  longitude: currentUserLocation.lng,
                  latitude: currentUserLocation.lat,
                  zoom: 14,
                }}
                style={{ width: '100%', height: '100%' }}
                mapStyle="mapbox://styles/mapbox/light-v11"
                mapboxAccessToken={process.env.NEXT_PUBLIC_MAPBOX_TOKEN}
                onMove={handleMapMove}
              >
                <NavigationControl position="top-right" />

                {/* Vendor Markers */}
                {sortedVendors.map((vendor) => (
                  <Marker
                    key={vendor.id}
                    longitude={vendor.location.lng}
                    latitude={vendor.location.lat}
                    anchor="center"
                    onClick={() => handleVendorClick(vendor)}
                  >
                    <div onMouseEnter={() => setHoveredVendor(vendor.id)} onMouseLeave={() => setHoveredVendor(null)}>
                      <VendorPin vendor={vendor} isHovered={hoveredVendor === vendor.id} />
                    </div>
                  </Marker>
                ))}

                {/* Project Markers */}
                {mockProjects.map((project) => (
                  <Marker
                    key={project.id}
                    longitude={project.location.lng}
                    latitude={project.location.lat}
                    anchor="center"
                    onClick={() => setPopupProject(project)}
                  >
                    <ProjectPin project={project} />
                  </Marker>
                ))}

                {/* Project Popup */}
                {popupProject && (
                  <Popup
                    longitude={popupProject.location.lng}
                    latitude={popupProject.location.lat}
                    anchor="bottom"
                    onClose={() => setPopupProject(null)}
                    closeOnClick={false}
                  >
                    <div className="p-2 min-w-[200px]">
                      <p className="font-medium text-slate-900">{popupProject.title}</p>
                      <p className="text-sm text-slate-500">
                        by {mockVendors.find(v => v.id === popupProject.vendorId)?.name}
                      </p>
                      <p className="text-xs text-slate-400 mt-1">{popupProject.homeownerName}'s home</p>
                    </div>
                  </Popup>
                )}
              </Map>

              {/* Search This Area Button */}
              {mapMoved && (
                <button
                  onClick={handleSearchThisArea}
                  className="absolute top-4 left-1/2 -translate-x-1/2 px-4 py-2 bg-white rounded-full shadow-lg border border-slate-200 text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors flex items-center gap-2"
                >
                  <Search className="w-4 h-4" />
                  Search This Area
                </button>
              )}
            </div>
          </div>

          {/* Mobile Map + Drawer */}
          <div className="lg:hidden h-[60vh] rounded-xl overflow-hidden border border-slate-200 relative">
            <Map
              ref={mapRef}
              initialViewState={{
                longitude: currentUserLocation.lng,
                latitude: currentUserLocation.lat,
                zoom: 14,
              }}
              style={{ width: '100%', height: '100%' }}
              mapStyle="mapbox://styles/mapbox/light-v11"
              mapboxAccessToken={process.env.NEXT_PUBLIC_MAPBOX_TOKEN}
            >
              <NavigationControl position="top-right" />

              {sortedVendors.map((vendor) => (
                <Marker
                  key={vendor.id}
                  longitude={vendor.location.lng}
                  latitude={vendor.location.lat}
                  anchor="center"
                >
                  <VendorPin vendor={vendor} isHovered={hoveredVendor === vendor.id} />
                </Marker>
              ))}
            </Map>
          </div>

          <MobileDirectoryDrawer
            vendors={sortedVendors}
            selectedVendor={hoveredVendor}
            onVendorSelect={handleVendorClick}
            isExpanded={mobileDrawerExpanded}
            onToggle={() => setMobileDrawerExpanded(!mobileDrawerExpanded)}
          />
        </>
      )}

      {/* Feed Mode */}
      {viewMode === 'feed' && (
        <div className="flex gap-6">
          {/* Main Feed */}
          <div className="flex-1 max-w-2xl space-y-4">
            {posts.map((post) => (
              <FeedPostCard
                key={post.id}
                post={post}
                onLike={handleLike}
                onSave={handleSave}
                onVendorClick={handleVendorClick}
              />
            ))}
          </div>

          {/* Desktop Sidebar */}
          <div className="hidden lg:block w-80">
            <TrendingSidebar
              trendingVendors={mockTrendingVendors}
              upcomingEvents={mockUpcomingEvents}
              onVendorClick={handleTrendingVendorClick}
            />
          </div>
        </div>
      )}

      {/* Vendor Profile Modal */}
      {selectedVendor && (
        <VendorProfileModal
          vendor={selectedVendor}
          onClose={() => setSelectedVendor(null)}
        />
      )}
    </div>
  );
}
