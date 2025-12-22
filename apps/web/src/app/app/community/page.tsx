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
import { getDemoImage } from '@/lib/imageUtils';

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
  { id: 'all', label: 'All Trades', icon: Home, color: 'bg-slate-100 text-slate-700' },
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
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'mikes-plumbing'),
    coverUrl: getDemoImage('plumbing-work', 400, 200, 'mikes-cover'),
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
        beforeImage: getDemoImage('bathroom-before', 300, 200, 'bath-before-1'),
        afterImage: getDemoImage('bathroom-after', 300, 200, 'bath-after-1'),
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
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'country-landscape'),
    coverUrl: getDemoImage('landscaping', 400, 200, 'landscape-cover'),
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
        beforeImage: getDemoImage('yard-before', 300, 200, 'yard-before-1'),
        afterImage: getDemoImage('yard-after', 300, 200, 'yard-after-1'),
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
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'elite-electric'),
    coverUrl: getDemoImage('electrical-work', 400, 200, 'electric-cover'),
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
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'comfort-zone'),
    coverUrl: getDemoImage('hvac-work', 400, 200, 'hvac-cover'),
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
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'perfect-painters'),
    coverUrl: getDemoImage('painting-work', 400, 200, 'paint-cover'),
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
    logoUrl: getDemoImage('vendor-logo', 80, 80, 'handy-dan'),
    coverUrl: getDemoImage('handyman-work', 400, 200, 'handy-cover'),
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
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <div className="bg-white border-b border-slate-200 sticky top-0 z-20">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Find Contractors</h1>
              <p className="text-sm text-slate-500">Trusted pros used by your neighbors</p>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setViewMode('map')}
                className={`p-2 rounded-lg ${viewMode === 'map' ? 'bg-emerald-100 text-emerald-700' : 'text-slate-400 hover:bg-slate-100'}`}
              >
                <MapIcon className="w-5 h-5" />
              </button>
              <button
                onClick={() => setViewMode('grid')}
                className={`p-2 rounded-lg ${viewMode === 'grid' ? 'bg-emerald-100 text-emerald-700' : 'text-slate-400 hover:bg-slate-100'}`}
              >
                <Grid3X3 className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Search */}
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <input
              type="text"
              placeholder="Search by name or specialty..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 border border-slate-300 rounded-xl focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
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
                    ? 'bg-emerald-600 text-white'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
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
                      ${vendor.havenTrusted ? 'bg-emerald-600' : 'bg-slate-600'}
                      ${selectedVendor?.id === vendor.id ? 'ring-4 ring-emerald-300 scale-110' : ''}
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
            <div className="w-full lg:w-96 bg-white border-l border-slate-200 overflow-y-auto">
              <div className="p-4 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-slate-600">
                    {sortedVendors.length} contractors found
                  </span>
                  <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value as SortOption)}
                    className="text-sm border-none bg-transparent text-emerald-600 font-medium focus:ring-0"
                  >
                    <option value="neighbors">Most Used by Neighbors</option>
                    <option value="rating">Highest Rated</option>
                    <option value="nearest">Nearest</option>
                    <option value="projects">Most Projects</option>
                  </select>
                </div>
              </div>
              <div className="divide-y divide-slate-100">
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
              <span className="text-sm font-medium text-slate-600">
                {sortedVendors.length} contractors found
              </span>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as SortOption)}
                className="text-sm border border-slate-300 rounded-lg px-3 py-1.5 focus:ring-2 focus:ring-emerald-500"
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
    <div className="min-w-[280px]">
      <div className="flex items-start gap-3">
        <img
          src={vendor.logoUrl}
          alt={vendor.name}
          className="w-12 h-12 rounded-lg object-cover"
        />
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <h3 className="font-semibold text-slate-900">{vendor.name}</h3>
            {vendor.havenTrusted && (
              <span className="px-1.5 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded">
                Haven Trusted
              </span>
            )}
          </div>
          <div className="flex items-center gap-2 text-sm text-slate-500">
            <Star className="w-4 h-4 text-yellow-500 fill-current" />
            <span>{vendor.rating}</span>
            <span>•</span>
            <span>{vendor.reviewCount} reviews</span>
          </div>
        </div>
      </div>
      <div className="mt-3 flex items-center gap-4 text-sm text-slate-600">
        <div className="flex items-center gap-1">
          <Users className="w-4 h-4" />
          <span>{vendor.neighborsUsed} neighbors</span>
        </div>
        <div className="flex items-center gap-1">
          <MapPin className="w-4 h-4" />
          <span>{vendor.distance} mi</span>
        </div>
      </div>
      <div className="mt-3 flex gap-2">
        <button className="flex-1 px-3 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700">
          Request Quote
        </button>
        <a
          href={`tel:${vendor.phone}`}
          className="px-3 py-2 border border-slate-300 rounded-lg hover:bg-slate-50"
        >
          <Phone className="w-4 h-4 text-slate-600" />
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
        isSelected ? 'bg-emerald-50' : 'hover:bg-slate-50'
      }`}
    >
      <div className="flex gap-3">
        <img
          src={vendor.logoUrl}
          alt={vendor.name}
          className="w-14 h-14 rounded-lg object-cover"
        />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h3 className="font-medium text-slate-900 truncate">{vendor.name}</h3>
            {vendor.havenTrusted && (
              <Shield className="w-4 h-4 text-emerald-600 flex-shrink-0" />
            )}
          </div>
          <div className="flex items-center gap-2 text-sm text-slate-500">
            <Star className="w-3.5 h-3.5 text-yellow-500 fill-current" />
            <span>{vendor.rating}</span>
            <span>•</span>
            <span>{vendor.priceTier}</span>
            <span>•</span>
            <span>{vendor.distance} mi</span>
          </div>
          <div className="mt-1 flex items-center gap-1 text-xs text-emerald-600">
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
    <div className="bg-white rounded-xl border border-slate-200 overflow-hidden hover:shadow-lg transition-shadow">
      {/* Cover/Project Image */}
      <div className="relative h-40">
        <img
          src={recentProject?.afterImage || vendor.coverUrl}
          alt={vendor.name}
          className="w-full h-full object-cover"
        />
        {vendor.havenTrusted && (
          <div className="absolute top-2 left-2 px-2 py-1 bg-emerald-600 text-white text-xs font-medium rounded-full flex items-center gap-1">
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
            src={vendor.logoUrl}
            alt={vendor.name}
            className="w-12 h-12 rounded-lg object-cover"
          />
          <div className="flex-1">
            <h3 className="font-semibold text-slate-900">{vendor.name}</h3>
            <div className="flex items-center gap-2 text-sm text-slate-500">
              <Star className="w-4 h-4 text-yellow-500 fill-current" />
              <span>{vendor.rating}</span>
              <span>({vendor.reviewCount})</span>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="mt-3 grid grid-cols-3 gap-2 text-center">
          <div className="py-2 bg-slate-50 rounded-lg">
            <div className="text-lg font-semibold text-slate-900">{vendor.neighborsUsed}</div>
            <div className="text-xs text-slate-500">Neighbors</div>
          </div>
          <div className="py-2 bg-slate-50 rounded-lg">
            <div className="text-lg font-semibold text-slate-900">{vendor.totalProjects}</div>
            <div className="text-xs text-slate-500">Projects</div>
          </div>
          <div className="py-2 bg-slate-50 rounded-lg">
            <div className="text-lg font-semibold text-slate-900">{vendor.onTimeRate}%</div>
            <div className="text-xs text-slate-500">On Time</div>
          </div>
        </div>

        {/* Specialties */}
        <div className="mt-3 flex flex-wrap gap-1">
          {vendor.specialties.slice(0, 3).map(specialty => (
            <span key={specialty} className="px-2 py-1 bg-slate-100 text-slate-600 text-xs rounded-full">
              {specialty}
            </span>
          ))}
        </div>

        {/* Actions */}
        <div className="mt-4 flex gap-2">
          <button className="flex-1 px-3 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700">
            Request Quote
          </button>
          <button className="px-3 py-2 border border-slate-300 rounded-lg hover:bg-slate-50">
            <Heart className="w-4 h-4 text-slate-600" />
          </button>
        </div>
      </div>
    </div>
  );
}
