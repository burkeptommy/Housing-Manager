'use client';

import { useState, useEffect, useCallback } from 'react';
import { getApiClient } from '@/lib/api';
import type { Vendor } from '@haven/core';

type VendorCategory =
  | 'HVAC_SERVICE' | 'PLUMBING' | 'ELECTRICAL' | 'ROOFING' | 'LANDSCAPING'
  | 'PEST_CONTROL' | 'CLEANING' | 'POOL_SERVICE' | 'SEPTIC_SERVICE'
  | 'GUTTER_CLEANING' | 'CHIMNEY_SWEEP' | 'HANDYMAN' | 'OTHER';

const categoryLabels: Record<string, string> = {
  HVAC_SERVICE: 'HVAC',
  PLUMBING: 'Plumbing',
  ELECTRICAL: 'Electrical',
  ROOFING: 'Roofing',
  LANDSCAPING: 'Landscaping',
  LAWN_CARE: 'Lawn Care',
  PEST_CONTROL: 'Pest Control',
  CLEANING: 'Cleaning',
  POOL_SERVICE: 'Pool Service',
  SEPTIC_SERVICE: 'Septic Service',
  GUTTER_CLEANING: 'Gutter Cleaning',
  CHIMNEY_SWEEP: 'Chimney Sweep',
  HANDYMAN: 'Handyman',
  ELECTRIC: 'Electric Utility',
  GAS: 'Gas Utility',
  WATER_SEWER: 'Water/Sewer',
  INTERNET: 'Internet',
  SECURITY_MONITORING: 'Security',
  OTHER: 'Other',
};

const categoryColors: Record<string, string> = {
  HVAC_SERVICE: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  PLUMBING: 'bg-cyan-100 text-cyan-700 dark:bg-cyan-900/30 dark:text-cyan-400',
  ELECTRICAL: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
  PEST_CONTROL: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
  CLEANING: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
  LAWN_CARE: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
  LANDSCAPING: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  POOL_SERVICE: 'bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-400',
  SEPTIC_SERVICE: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
  GUTTER_CLEANING: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
  CHIMNEY_SWEEP: 'bg-stone-100 text-stone-700 dark:bg-stone-900/30 dark:text-stone-400',
  HANDYMAN: 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400',
  OTHER: 'bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-300',
};

interface VendorWithStats extends Vendor {
  workOrderCount?: number;
  avgRating?: number;
}

export default function ManagerVendorsPage() {
  const [vendors, setVendors] = useState<VendorWithStats[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [selectedVendor, setSelectedVendor] = useState<VendorWithStats | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);

  const api = getApiClient();

  const loadVendors = useCallback(async () => {
    try {
      const vendorsData = await api.getVendors();
      setVendors(vendorsData as VendorWithStats[]);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to load vendors';
      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, [api]);

  useEffect(() => {
    loadVendors();
  }, [loadVendors]);

  const filteredVendors = vendors.filter((vendor) => {
    const matchesSearch =
      !searchQuery ||
      vendor.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      vendor.serviceDescription?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesCategory =
      categoryFilter === 'all' || vendor.category === categoryFilter;

    return matchesSearch && matchesCategory;
  });

  const categories = [...new Set(vendors.map((v) => v.category))].sort();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Vendor Management</h1>
          <p className="text-slate-600 dark:text-slate-400">
            Manage service providers and contractors
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Add Vendor
        </button>
      </div>

      {/* Error */}
      {error && (
        <div className="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="flex-1">
          <div className="relative">
            <svg
              className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
            <input
              type="text"
              placeholder="Search vendors..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
            />
          </div>
        </div>
        <select
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
          className="px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
        >
          <option value="all">All Categories</option>
          {categories.map((cat) => (
            <option key={cat} value={cat}>
              {categoryLabels[cat] || cat}
            </option>
          ))}
        </select>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{vendors.length}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Total Vendors</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {vendors.filter((v) => v.isVerified).length}
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Verified</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {vendors.filter((v) => v.isLocal).length}
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Local Providers</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{categories.length}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Categories</p>
            </div>
          </div>
        </div>
      </div>

      {/* Vendors Grid */}
      {filteredVendors.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredVendors.map((vendor) => (
            <div
              key={vendor.id}
              onClick={() => setSelectedVendor(vendor)}
              className="card cursor-pointer hover:shadow-md transition-shadow"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="w-12 h-12 rounded-lg bg-slate-100 dark:bg-slate-700 flex items-center justify-center">
                  <svg className="w-6 h-6 text-slate-500 dark:text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
                <span
                  className={`text-xs font-medium px-2 py-1 rounded-full ${
                    categoryColors[vendor.category] || categoryColors.OTHER
                  }`}
                >
                  {categoryLabels[vendor.category] || vendor.category}
                </span>
              </div>

              <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
                {vendor.displayName}
              </h3>

              {vendor.serviceDescription && (
                <p className="text-sm text-slate-600 dark:text-slate-400 mb-3 line-clamp-2">
                  {vendor.serviceDescription}
                </p>
              )}

              <div className="flex items-center gap-4 text-sm text-slate-500 dark:text-slate-400">
                {vendor.phone && (
                  <div className="flex items-center gap-1">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                    </svg>
                    <span>{vendor.phone}</span>
                  </div>
                )}
                {vendor.isVerified && (
                  <div className="flex items-center gap-1 text-emerald-600 dark:text-emerald-400">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                    </svg>
                    <span>Verified</span>
                  </div>
                )}
              </div>

              {vendor.rating && (
                <div className="flex items-center gap-1 mt-2">
                  {[...Array(5)].map((_, i) => (
                    <svg
                      key={i}
                      className={`w-4 h-4 ${
                        i < Math.round(vendor.rating || 0)
                          ? 'text-yellow-400'
                          : 'text-slate-300 dark:text-slate-600'
                      }`}
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                  ))}
                  <span className="text-sm text-slate-500 ml-1">
                    ({vendor.reviewCount || 0})
                  </span>
                </div>
              )}
            </div>
          ))}
        </div>
      ) : (
        <div className="card text-center py-12">
          <div className="w-16 h-16 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <h2 className="text-xl font-semibold text-slate-900 dark:text-white mb-2">
            No vendors found
          </h2>
          <p className="text-slate-600 dark:text-slate-400">
            {searchQuery || categoryFilter !== 'all'
              ? 'Try adjusting your filters'
              : 'Add vendors to get started'}
          </p>
        </div>
      )}

      {/* Vendor Detail Modal */}
      {selectedVendor && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
            <div className="fixed inset-0 bg-black/50 transition-opacity" onClick={() => setSelectedVendor(null)} />

            <div className="relative transform overflow-hidden rounded-xl bg-white dark:bg-slate-800 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg">
              {/* Header */}
              <div className="border-b border-slate-200 dark:border-slate-700 px-6 py-4">
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                      {selectedVendor.displayName}
                    </h3>
                    <span
                      className={`inline-block mt-1 text-xs font-medium px-2 py-0.5 rounded-full ${
                        categoryColors[selectedVendor.category] || categoryColors.OTHER
                      }`}
                    >
                      {categoryLabels[selectedVendor.category] || selectedVendor.category}
                    </span>
                  </div>
                  <button
                    onClick={() => setSelectedVendor(null)}
                    className="text-slate-400 hover:text-slate-500 dark:hover:text-slate-300"
                  >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              </div>

              {/* Content */}
              <div className="px-6 py-4 space-y-4">
                {selectedVendor.serviceDescription && (
                  <div>
                    <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Description</h4>
                    <p className="text-slate-900 dark:text-white">{selectedVendor.serviceDescription}</p>
                  </div>
                )}

                <div className="grid grid-cols-2 gap-4">
                  {selectedVendor.contactName && (
                    <div>
                      <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Contact</h4>
                      <p className="text-slate-900 dark:text-white">{selectedVendor.contactName}</p>
                    </div>
                  )}
                  {selectedVendor.phone && (
                    <div>
                      <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Phone</h4>
                      <a href={`tel:${selectedVendor.phone}`} className="text-emerald-600 dark:text-emerald-400 hover:underline">
                        {selectedVendor.phone}
                      </a>
                    </div>
                  )}
                  {selectedVendor.email && (
                    <div>
                      <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Email</h4>
                      <a href={`mailto:${selectedVendor.email}`} className="text-emerald-600 dark:text-emerald-400 hover:underline">
                        {selectedVendor.email}
                      </a>
                    </div>
                  )}
                  {selectedVendor.websiteUrl && (
                    <div>
                      <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Website</h4>
                      <a
                        href={selectedVendor.websiteUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-emerald-600 dark:text-emerald-400 hover:underline"
                      >
                        Visit Website
                      </a>
                    </div>
                  )}
                </div>

                {(selectedVendor.addressLine1 || selectedVendor.city) && (
                  <div>
                    <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Address</h4>
                    <p className="text-slate-900 dark:text-white">
                      {selectedVendor.addressLine1}
                      {selectedVendor.addressLine2 && <br />}
                      {selectedVendor.addressLine2}
                      {selectedVendor.city && (
                        <>
                          <br />
                          {selectedVendor.city}, {selectedVendor.state} {selectedVendor.postalCode}
                        </>
                      )}
                    </p>
                  </div>
                )}

                {selectedVendor.licenseNumber && (
                  <div>
                    <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">License Number</h4>
                    <p className="text-slate-900 dark:text-white">{selectedVendor.licenseNumber}</p>
                  </div>
                )}

                <div className="flex items-center gap-4 pt-2">
                  {selectedVendor.isVerified && (
                    <div className="flex items-center gap-1 text-emerald-600 dark:text-emerald-400">
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                      </svg>
                      <span className="text-sm font-medium">Verified</span>
                    </div>
                  )}
                  {selectedVendor.isLocal && (
                    <div className="flex items-center gap-1 text-blue-600 dark:text-blue-400">
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                      </svg>
                      <span className="text-sm font-medium">Local Provider</span>
                    </div>
                  )}
                </div>
              </div>

              {/* Footer */}
              <div className="border-t border-slate-200 dark:border-slate-700 px-6 py-4 flex gap-3">
                <button
                  onClick={() => setSelectedVendor(null)}
                  className="flex-1 px-4 py-2 text-slate-700 dark:text-slate-300 font-medium rounded-lg border border-slate-300 dark:border-slate-600 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                >
                  Close
                </button>
                <button
                  onClick={() => {
                    // TODO: Implement edit functionality
                    setSelectedVendor(null);
                  }}
                  className="flex-1 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
                >
                  Edit Vendor
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add Vendor Modal Placeholder */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
            <div className="fixed inset-0 bg-black/50 transition-opacity" onClick={() => setShowAddModal(false)} />

            <div className="relative transform overflow-hidden rounded-xl bg-white dark:bg-slate-800 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg">
              <div className="border-b border-slate-200 dark:border-slate-700 px-6 py-4">
                <div className="flex items-start justify-between">
                  <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Add New Vendor</h3>
                  <button
                    onClick={() => setShowAddModal(false)}
                    className="text-slate-400 hover:text-slate-500 dark:hover:text-slate-300"
                  >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              </div>

              <div className="px-6 py-4">
                <p className="text-slate-600 dark:text-slate-400 text-center py-8">
                  Vendor creation form coming soon. For now, vendors can be added via the admin panel or database.
                </p>
              </div>

              <div className="border-t border-slate-200 dark:border-slate-700 px-6 py-4">
                <button
                  onClick={() => setShowAddModal(false)}
                  className="w-full px-4 py-2 text-slate-700 dark:text-slate-300 font-medium rounded-lg border border-slate-300 dark:border-slate-600 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
