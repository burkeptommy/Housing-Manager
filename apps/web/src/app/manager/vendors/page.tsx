'use client';

import { useState } from 'react';
import {
  Wrench,
  Search,
  Plus,
  Upload,
  Star,
  Phone,
  Mail,
  ClipboardList,
  ChevronRight,
  X,
  MapPin,
  Clock,
  FileText,
  Shield,
  Building2,
  Zap,
  Snowflake,
  Home,
  Leaf,
  Sparkles,
  Bug,
  Droplets,
  BarChart3,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type VendorCategory = 'plumbing' | 'electrical' | 'hvac' | 'roofing' | 'landscaping' | 'cleaning' | 'pest_control' | 'pool';

interface Vendor {
  id: string;
  name: string;
  category: VendorCategory;
  contactName: string;
  phone: string;
  email?: string;
  serviceArea: string;
  priceLevel: 1 | 2 | 3; // $ to $$$
  rating: number;
  reviewCount: number;
  responseTime: string;
  usageCount: number;
  isVerified: boolean;
  recentJobs: { household: string; date: string }[];
  notes?: string;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const mockVendors: Vendor[] = [
  {
    id: 'v1',
    name: "Mike's Plumbing Pro",
    category: 'plumbing',
    contactName: 'Mike Chen',
    phone: '(512) 555-PLMB',
    email: 'mike@mikesplumbing.com',
    serviceArea: 'Austin Metro',
    priceLevel: 1,
    rating: 4.9,
    reviewCount: 127,
    responseTime: '2-4 hours',
    usageCount: 47,
    isVerified: true,
    recentJobs: [
      { household: 'Smith', date: 'Dec 18' },
      { household: 'Johnson', date: 'Dec 10' },
    ],
  },
  {
    id: 'v2',
    name: 'AirFlow HVAC Services',
    category: 'hvac',
    contactName: 'John Davis',
    phone: '(512) 555-HVAC',
    email: 'service@airflowhvac.com',
    serviceArea: 'Greater Austin',
    priceLevel: 2,
    rating: 4.8,
    reviewCount: 89,
    responseTime: '4-6 hours',
    usageCount: 32,
    isVerified: true,
    recentJobs: [
      { household: 'Smith', date: 'Dec 20' },
      { household: 'Miller', date: 'Dec 5' },
    ],
  },
  {
    id: 'v3',
    name: 'Bright Spark Electric',
    category: 'electrical',
    contactName: 'Tom Wilson',
    phone: '(512) 555-ELEC',
    serviceArea: 'Austin Area',
    priceLevel: 2,
    rating: 4.7,
    reviewCount: 64,
    responseTime: 'Same day',
    usageCount: 28,
    isVerified: true,
    recentJobs: [
      { household: 'Johnson', date: 'Dec 15' },
    ],
  },
  {
    id: 'v4',
    name: 'Green Thumb Landscaping',
    category: 'landscaping',
    contactName: 'Maria Garcia',
    phone: '(512) 555-LAWN',
    email: 'info@greenthumb.com',
    serviceArea: 'Austin Metro',
    priceLevel: 1,
    rating: 4.6,
    reviewCount: 156,
    responseTime: '1-2 days',
    usageCount: 52,
    isVerified: true,
    recentJobs: [
      { household: 'Smith', date: 'Dec 19' },
      { household: 'Johnson', date: 'Dec 19' },
      { household: 'Miller', date: 'Dec 18' },
    ],
  },
  {
    id: 'v5',
    name: 'Apex Roofing Co',
    category: 'roofing',
    contactName: 'Dave Brown',
    phone: '(512) 555-ROOF',
    serviceArea: 'Central Texas',
    priceLevel: 3,
    rating: 4.9,
    reviewCount: 42,
    responseTime: '24-48 hours',
    usageCount: 8,
    isVerified: true,
    recentJobs: [
      { household: 'Miller', date: 'Nov 28' },
    ],
  },
  {
    id: 'v6',
    name: 'Crystal Clear Pools',
    category: 'pool',
    contactName: 'Steve Martinez',
    phone: '(512) 555-POOL',
    email: 'service@crystalclear.com',
    serviceArea: 'Austin Metro',
    priceLevel: 2,
    rating: 4.5,
    reviewCount: 78,
    responseTime: 'Weekly service',
    usageCount: 24,
    isVerified: false,
    recentJobs: [
      { household: 'Smith', date: 'Dec 21' },
    ],
  },
  {
    id: 'v7',
    name: 'Sparkle Clean Services',
    category: 'cleaning',
    contactName: 'Lisa Wong',
    phone: '(512) 555-CLEN',
    email: 'book@sparkleclean.com',
    serviceArea: 'Austin',
    priceLevel: 2,
    rating: 4.8,
    reviewCount: 203,
    responseTime: '1-2 days',
    usageCount: 36,
    isVerified: true,
    recentJobs: [
      { household: 'Johnson', date: 'Dec 20' },
      { household: 'Smith', date: 'Dec 15' },
    ],
  },
  {
    id: 'v8',
    name: 'Bug-B-Gone Pest Control',
    category: 'pest_control',
    contactName: 'Rick Taylor',
    phone: '(512) 555-BUGS',
    serviceArea: 'Greater Austin',
    priceLevel: 1,
    rating: 4.4,
    reviewCount: 91,
    responseTime: 'Same day',
    usageCount: 15,
    isVerified: true,
    recentJobs: [
      { household: 'Miller', date: 'Dec 12' },
    ],
  },
];

// ============================================================================
// CATEGORY CONFIG
// ============================================================================

const categoryConfig: Record<VendorCategory, { label: string; icon: React.ReactNode; bgColor: string; textColor: string }> = {
  plumbing: {
    label: 'Plumbing',
    icon: <Wrench className="w-4 h-4" />,
    bgColor: 'bg-blue-100',
    textColor: 'text-blue-600',
  },
  electrical: {
    label: 'Electrical',
    icon: <Zap className="w-4 h-4" />,
    bgColor: 'bg-amber-100',
    textColor: 'text-amber-600',
  },
  hvac: {
    label: 'HVAC',
    icon: <Snowflake className="w-4 h-4" />,
    bgColor: 'bg-cyan-100',
    textColor: 'text-cyan-600',
  },
  roofing: {
    label: 'Roofing',
    icon: <Home className="w-4 h-4" />,
    bgColor: 'bg-slate-200',
    textColor: 'text-slate-700',
  },
  landscaping: {
    label: 'Landscaping',
    icon: <Leaf className="w-4 h-4" />,
    bgColor: 'bg-green-100',
    textColor: 'text-green-600',
  },
  cleaning: {
    label: 'Cleaning',
    icon: <Sparkles className="w-4 h-4" />,
    bgColor: 'bg-purple-100',
    textColor: 'text-purple-600',
  },
  pest_control: {
    label: 'Pest Control',
    icon: <Bug className="w-4 h-4" />,
    bgColor: 'bg-red-100',
    textColor: 'text-red-600',
  },
  pool: {
    label: 'Pool',
    icon: <Droplets className="w-4 h-4" />,
    bgColor: 'bg-blue-50',
    textColor: 'text-blue-500',
  },
};

const allCategories: VendorCategory[] = ['plumbing', 'electrical', 'hvac', 'roofing', 'landscaping', 'cleaning', 'pest_control', 'pool'];

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function VendorNetworkPage() {
  const [vendors] = useState<Vendor[]>(mockVendors);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<VendorCategory | 'all'>('all');
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);

  // Filter vendors
  const filteredVendors = vendors.filter(vendor => {
    const matchesSearch = !searchQuery ||
      vendor.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      vendor.contactName.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || vendor.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  // Get frequently used vendors (top 6 by usage)
  const frequentlyUsed = [...vendors].sort((a, b) => b.usageCount - a.usageCount).slice(0, 6);

  const getPriceLevel = (level: number) => {
    return '$'.repeat(level);
  };

  // Vendor Card Component
  const VendorCard = ({ vendor }: { vendor: Vendor }) => {
    const category = categoryConfig[vendor.category];

    return (
      <div
        onClick={() => setSelectedVendor(vendor)}
        className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 cursor-pointer hover:shadow-md hover:border-indigo-200 transition-all"
      >
        {/* Header */}
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-2">
            <div className={`w-10 h-10 ${category.bgColor} rounded-lg flex items-center justify-center ${category.textColor}`}>
              {category.icon}
            </div>
            <div>
              <h3 className="font-semibold text-slate-900">{vendor.name}</h3>
              <div className="flex items-center gap-2 text-sm text-slate-500">
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${category.bgColor} ${category.textColor}`}>
                  {category.label}
                </span>
                <span>•</span>
                <span>{vendor.serviceArea}</span>
                <span>•</span>
                <span className="text-slate-400">{getPriceLevel(vendor.priceLevel)}</span>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-1">
            <Star className="w-4 h-4 text-amber-500 fill-amber-500" />
            <span className="font-medium text-slate-900">{vendor.rating}</span>
            <span className="text-slate-400 text-sm">({vendor.reviewCount})</span>
          </div>
        </div>

        {/* Contact & Stats */}
        <div className="border-t border-slate-100 pt-3 mb-3">
          <div className="flex items-center gap-4 text-sm text-slate-600">
            <div className="flex items-center gap-1">
              <Phone className="w-4 h-4 text-slate-400" />
              <span>{vendor.contactName}</span>
              <span>•</span>
              <span>{vendor.phone}</span>
            </div>
          </div>
          <div className="flex items-center gap-4 mt-2 text-sm text-slate-500">
            <div className="flex items-center gap-1">
              <Clock className="w-4 h-4 text-slate-400" />
              <span>Response: {vendor.responseTime}</span>
            </div>
            <span>•</span>
            <span>Used {vendor.usageCount} times</span>
            {vendor.isVerified && (
              <>
                <span>•</span>
                <div className="flex items-center gap-1 text-emerald-600">
                  <Shield className="w-4 h-4" />
                  <span>Verified</span>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Recent Jobs */}
        {vendor.recentJobs.length > 0 && (
          <div className="border-t border-slate-100 pt-3 mb-3">
            <p className="text-sm text-slate-500">
              Recent: {vendor.recentJobs.map((job, i) => (
                <span key={i}>
                  {job.household} ({job.date}){i < vendor.recentJobs.length - 1 ? ', ' : ''}
                </span>
              ))}
            </p>
          </div>
        )}

        {/* Actions */}
        <div className="border-t border-slate-100 pt-3 flex items-center gap-2">
          <button
            onClick={(e) => { e.stopPropagation(); window.location.href = `tel:${vendor.phone}`; }}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
          >
            <Phone className="w-4 h-4" />
            Call
          </button>
          {vendor.email && (
            <button
              onClick={(e) => { e.stopPropagation(); window.location.href = `mailto:${vendor.email}`; }}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
            >
              <Mail className="w-4 h-4" />
              Email
            </button>
          )}
          <button
            onClick={(e) => { e.stopPropagation(); }}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <ClipboardList className="w-4 h-4" />
            Work Order
          </button>
          <button
            onClick={(e) => { e.stopPropagation(); setSelectedVendor(vendor); }}
            className="ml-auto inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
          >
            View
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center">
              <Wrench className="w-6 h-6 text-indigo-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Vendor Network</h1>
              <p className="text-slate-500">Manage your trusted service providers</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowAddModal(true)}
              className="inline-flex items-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition-colors"
            >
              <Plus className="w-5 h-5" />
              Add Vendor
            </button>
            <button className="inline-flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 text-slate-700 rounded-lg font-medium hover:bg-slate-50 transition-colors">
              <Upload className="w-5 h-5" />
              Import
            </button>
          </div>
        </div>

        {/* Search */}
        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
          <input
            type="text"
            placeholder="Search vendors..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
          />
        </div>

        {/* Category Pills */}
        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => setSelectedCategory('all')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              selectedCategory === 'all'
                ? 'bg-indigo-600 text-white'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            All
          </button>
          {allCategories.map(cat => {
            const config = categoryConfig[cat];
            return (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`inline-flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  selectedCategory === cat
                    ? 'bg-indigo-600 text-white'
                    : `${config.bgColor} ${config.textColor} hover:opacity-80`
                }`}
              >
                {config.icon}
                {config.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Frequently Used Section */}
      {selectedCategory === 'all' && !searchQuery && (
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-slate-900">Frequently Used</h2>
            <button className="text-sm text-indigo-600 hover:text-indigo-700 font-medium">
              View All
            </button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {frequentlyUsed.map(vendor => (
              <VendorCard key={vendor.id} vendor={vendor} />
            ))}
          </div>
        </div>
      )}

      {/* All Vendors / Filtered */}
      {(selectedCategory !== 'all' || searchQuery) && (
        <div>
          <h2 className="text-lg font-semibold text-slate-900 mb-4">
            {searchQuery ? `Search Results (${filteredVendors.length})` : `${categoryConfig[selectedCategory as VendorCategory]?.label || 'All'} Vendors`}
          </h2>
          {filteredVendors.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredVendors.map(vendor => (
                <VendorCard key={vendor.id} vendor={vendor} />
              ))}
            </div>
          ) : (
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center">
              <Building2 className="w-12 h-12 text-slate-300 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-slate-900 mb-2">No vendors found</h3>
              <p className="text-slate-500">Try adjusting your search or filters</p>
            </div>
          )}
        </div>
      )}

      {/* Vendor Detail Modal */}
      {selectedVendor && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-hidden">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 ${categoryConfig[selectedVendor.category].bgColor} rounded-xl flex items-center justify-center ${categoryConfig[selectedVendor.category].textColor}`}>
                  {categoryConfig[selectedVendor.category].icon}
                </div>
                <div>
                  <h2 className="text-xl font-semibold text-slate-900">{selectedVendor.name}</h2>
                  <div className="flex items-center gap-2 text-sm text-slate-500">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${categoryConfig[selectedVendor.category].bgColor} ${categoryConfig[selectedVendor.category].textColor}`}>
                      {categoryConfig[selectedVendor.category].label}
                    </span>
                    <span>•</span>
                    <div className="flex items-center gap-1">
                      <Star className="w-4 h-4 text-amber-500 fill-amber-500" />
                      <span className="font-medium text-slate-900">{selectedVendor.rating}</span>
                      <span className="text-slate-400">({selectedVendor.reviewCount} reviews)</span>
                    </div>
                  </div>
                </div>
              </div>
              <button
                onClick={() => setSelectedVendor(null)}
                className="p-2 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto max-h-[60vh]">
              {/* Contact Info */}
              <div className="mb-6">
                <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3">Contact Information</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div className="flex items-center gap-3">
                    <Phone className="w-5 h-5 text-slate-400" />
                    <div>
                      <p className="text-sm text-slate-500">Phone</p>
                      <a href={`tel:${selectedVendor.phone}`} className="font-medium text-indigo-600 hover:text-indigo-700">
                        {selectedVendor.phone}
                      </a>
                    </div>
                  </div>
                  {selectedVendor.email && (
                    <div className="flex items-center gap-3">
                      <Mail className="w-5 h-5 text-slate-400" />
                      <div>
                        <p className="text-sm text-slate-500">Email</p>
                        <a href={`mailto:${selectedVendor.email}`} className="font-medium text-indigo-600 hover:text-indigo-700">
                          {selectedVendor.email}
                        </a>
                      </div>
                    </div>
                  )}
                  <div className="flex items-center gap-3">
                    <MapPin className="w-5 h-5 text-slate-400" />
                    <div>
                      <p className="text-sm text-slate-500">Service Area</p>
                      <p className="font-medium text-slate-900">{selectedVendor.serviceArea}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Clock className="w-5 h-5 text-slate-400" />
                    <div>
                      <p className="text-sm text-slate-500">Response Time</p>
                      <p className="font-medium text-slate-900">{selectedVendor.responseTime}</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Performance Metrics */}
              <div className="mb-6">
                <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3">Performance</h3>
                <div className="grid grid-cols-3 gap-4">
                  <div className="bg-slate-50 rounded-lg p-4 text-center">
                    <p className="text-2xl font-bold text-slate-900">{selectedVendor.usageCount}</p>
                    <p className="text-sm text-slate-500">Jobs Completed</p>
                  </div>
                  <div className="bg-slate-50 rounded-lg p-4 text-center">
                    <div className="flex items-center justify-center gap-1">
                      <Star className="w-5 h-5 text-amber-500 fill-amber-500" />
                      <span className="text-2xl font-bold text-slate-900">{selectedVendor.rating}</span>
                    </div>
                    <p className="text-sm text-slate-500">Avg Rating</p>
                  </div>
                  <div className="bg-slate-50 rounded-lg p-4 text-center">
                    <p className="text-2xl font-bold text-slate-900">95%</p>
                    <p className="text-sm text-slate-500">On-Time</p>
                  </div>
                </div>
              </div>

              {/* Recent Jobs */}
              <div className="mb-6">
                <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3">Recent Jobs</h3>
                <div className="space-y-2">
                  {selectedVendor.recentJobs.map((job, i) => (
                    <div key={i} className="flex items-center justify-between py-2 border-b border-slate-100 last:border-0">
                      <span className="text-slate-900">{job.household} Family</span>
                      <span className="text-sm text-slate-500">{job.date}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Documents */}
              <div className="mb-6">
                <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3">Documents</h3>
                <div className="space-y-2">
                  {[
                    { name: 'Insurance Certificate', status: 'verified' },
                    { name: 'Business License', status: 'verified' },
                    { name: 'W-9 Form', status: 'on_file' },
                  ].map((doc, i) => (
                    <div key={i} className="flex items-center justify-between py-2 border-b border-slate-100 last:border-0">
                      <div className="flex items-center gap-2">
                        <FileText className="w-4 h-4 text-slate-400" />
                        <span className="text-slate-900">{doc.name}</span>
                      </div>
                      <span className={`text-sm font-medium ${doc.status === 'verified' ? 'text-emerald-600' : 'text-slate-500'}`}>
                        {doc.status === 'verified' ? 'Verified' : 'On File'}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Manager Notes */}
              <div>
                <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3">Manager Notes (Private)</h3>
                <textarea
                  placeholder="Add private notes about this vendor..."
                  rows={3}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 resize-none"
                  defaultValue={selectedVendor.notes || ''}
                />
              </div>
            </div>

            {/* Modal Footer */}
            <div className="px-6 py-4 border-t border-slate-200 flex justify-between">
              <button className="inline-flex items-center gap-2 px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium transition-colors">
                <BarChart3 className="w-4 h-4" />
                View Full History
              </button>
              <div className="flex gap-3">
                <button
                  onClick={() => setSelectedVendor(null)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium transition-colors"
                >
                  Close
                </button>
                <button className="px-6 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition-colors flex items-center gap-2">
                  <ClipboardList className="w-4 h-4" />
                  Create Work Order
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add Vendor Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-lg w-full">
            <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-slate-900">Add New Vendor</h2>
              <button
                onClick={() => setShowAddModal(false)}
                className="p-2 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6">
              <p className="text-slate-500 text-center py-8">
                Vendor creation form coming soon.
              </p>
            </div>
            <div className="px-6 py-4 border-t border-slate-200 flex justify-end">
              <button
                onClick={() => setShowAddModal(false)}
                className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
