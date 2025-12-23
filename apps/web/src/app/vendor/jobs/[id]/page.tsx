'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import type { VendorJobDetail, VendorWorkOrderStatus } from '@haven/core';

// Mock data for demo
const mockJobDetail: VendorJobDetail = {
  id: 'wo-progress-1',
  title: 'Pool Pump Repair',
  description:
    'Pool pump making unusual noise. May need bearing replacement. Customer reports the pump has been running louder than usual for the past week.',
  status: 'ASSIGNED',
  scheduledStart: '2024-12-18T10:00:00Z',
  scheduledEnd: '2024-12-18T14:00:00Z',
  estimatedCost: 325,
  serviceArea: 'Beverly Hills',
  checkInAt: null,
  checkOutAt: null,
  proofImages: [],
  household: {
    id: 'h-beverly',
    name: 'Beverly Hills Estate',
    homeProfile: {
      address: '1200 Sunset Blvd, Beverly Hills, CA 90210',
      latitude: 34.0901,
      longitude: -118.4065,
    },
  },
  notes: [
    {
      id: 'note-1',
      body: 'Customer prefers contact via text. Gate code is 1234.',
      createdAt: '2024-12-16T10:00:00Z',
      author: {
        id: 'manager-1',
        firstName: 'Sarah',
        lastName: 'Harrison',
      },
    },
  ],
};

const STATUS_COLORS: Record<VendorWorkOrderStatus, string> = {
  DRAFT: 'bg-slate-100 text-slate-600',
  REQUESTED: 'bg-emerald-100 text-emerald-700',
  SCHEDULED: 'bg-purple-100 text-purple-700',
  OPEN: 'bg-green-100 text-green-700',
  ASSIGNED: 'bg-yellow-100 text-yellow-700',
  IN_PROGRESS: 'bg-orange-100 text-orange-700',
  COMPLETED: 'bg-emerald-100 text-emerald-700',
  VERIFIED: 'bg-emerald-100 text-emerald-700',
  CANCELLED: 'bg-red-100 text-red-700',
};

export default function JobDetailPage() {
  const params = useParams();
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [job, setJob] = useState<VendorJobDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isCheckingIn, setIsCheckingIn] = useState(false);
  const [isCheckingOut, setIsCheckingOut] = useState(false);
  const [locationError, setLocationError] = useState('');
  const [proofImages, setProofImages] = useState<string[]>([]);
  const [completionNotes, setCompletionNotes] = useState('');
  const [showCompleteModal, setShowCompleteModal] = useState(false);

  const loadJob = useCallback(async () => {
    setIsLoading(true);
    await new Promise((resolve) => setTimeout(resolve, 500));
    // In production, would fetch by params.id
    setJob(mockJobDetail);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    loadJob();
  }, [loadJob]);

  const getCurrentLocation = (): Promise<GeolocationPosition> => {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation is not supported'));
        return;
      }
      navigator.geolocation.getCurrentPosition(resolve, reject, {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0,
      });
    });
  };

  const handleCheckIn = async () => {
    if (!job) return;
    setIsCheckingIn(true);
    setLocationError('');

    try {
      const position = await getCurrentLocation();
      const { latitude, longitude } = position.coords;

      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 1000));

      // Update job state
      setJob({
        ...job,
        status: 'IN_PROGRESS',
        checkInAt: new Date().toISOString(),
      });
    } catch (error) {
      if (error instanceof GeolocationPositionError) {
        switch (error.code) {
          case error.PERMISSION_DENIED:
            setLocationError('Location permission denied. Please enable location access.');
            break;
          case error.POSITION_UNAVAILABLE:
            setLocationError('Location unavailable. Please try again.');
            break;
          case error.TIMEOUT:
            setLocationError('Location request timed out. Please try again.');
            break;
        }
      } else {
        setLocationError('Failed to get location. Please try again.');
      }
    } finally {
      setIsCheckingIn(false);
    }
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    // In production, would upload to cloud storage
    // For demo, we'll use data URLs
    Array.from(files).forEach((file) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        if (e.target?.result) {
          setProofImages((prev) => [...prev, e.target!.result as string]);
        }
      };
      reader.readAsDataURL(file);
    });
  };

  const handleRemoveImage = (index: number) => {
    setProofImages((prev) => prev.filter((_, i) => i !== index));
  };

  const handleCheckOut = async () => {
    if (!job || proofImages.length === 0) return;
    setIsCheckingOut(true);

    try {
      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 1500));

      // Update job state
      setJob({
        ...job,
        status: 'COMPLETED',
        checkOutAt: new Date().toISOString(),
        proofImages,
      });

      setShowCompleteModal(false);

      // Redirect to schedule after completion
      setTimeout(() => {
        router.push('/vendor/schedule');
      }, 2000);
    } catch {
      setLocationError('Failed to complete job. Please try again.');
    } finally {
      setIsCheckingOut(false);
    }
  };

  const formatDateTime = (dateStr: string | null) => {
    if (!dateStr) return 'TBD';
    return new Date(dateStr).toLocaleString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const formatCurrency = (amount: number | null) => {
    if (amount === null) return 'TBD';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const openInMaps = () => {
    if (!job?.household?.homeProfile) return;
    const { latitude, longitude, address } = job.household.homeProfile;
    if (!address) return;
    const encodedAddress = encodeURIComponent(address);
    // Try to open in Google Maps, fallback to Apple Maps
    const url = `https://www.google.com/maps/dir/?api=1&destination=${latitude || 0},${longitude || 0}&destination_place_id=${encodedAddress}`;
    window.open(url, '_blank');
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-600"></div>
      </div>
    );
  }

  if (!job) {
    return (
      <div className="text-center py-12">
        <h2 className="text-xl font-semibold text-slate-900 dark:text-white">Job not found</h2>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      {/* Header */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <button
            onClick={() => router.back()}
            className="flex items-center gap-1 text-sm text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white mb-2"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back
          </button>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{job.title}</h1>
          <div className="flex items-center gap-2 mt-2">
            <span className={`px-2.5 py-1 rounded text-sm font-medium ${STATUS_COLORS[job.status]}`}>
              {job.status.replace('_', ' ')}
            </span>
            <span className="text-slate-500 dark:text-slate-400">{job.household?.name || 'Unknown Location'}</span>
          </div>
        </div>
        <div className="text-right">
          <p className="text-2xl font-bold text-slate-900 dark:text-white">{formatCurrency(job.estimatedCost)}</p>
          <p className="text-sm text-slate-500 dark:text-slate-400">Estimated</p>
        </div>
      </div>

      {/* Location Error */}
      {locationError && (
        <div className="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
          <div className="flex items-center gap-2">
            <svg className="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <p className="text-sm text-red-600 dark:text-red-400">{locationError}</p>
          </div>
        </div>
      )}

      {/* Job Completed Success */}
      {job.status === 'COMPLETED' && (
        <div className="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
          <div className="flex items-center gap-3">
            <svg className="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <div>
              <p className="font-semibold text-green-700 dark:text-green-400">Job Completed!</p>
              <p className="text-sm text-green-600 dark:text-green-500">Awaiting manager verification.</p>
            </div>
          </div>
        </div>
      )}

      {/* Main Action Buttons */}
      {job.status === 'ASSIGNED' && (
        <button
          onClick={handleCheckIn}
          disabled={isCheckingIn}
          className="w-full py-4 px-6 bg-orange-600 hover:bg-orange-700 text-white rounded-xl font-semibold text-lg flex items-center justify-center gap-3 transition-colors disabled:opacity-50"
        >
          {isCheckingIn ? (
            <>
              <div className="w-6 h-6 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
              Getting Location...
            </>
          ) : (
            <>
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              Start Job (Check In)
            </>
          )}
        </button>
      )}

      {job.status === 'IN_PROGRESS' && (
        <button
          onClick={() => setShowCompleteModal(true)}
          className="w-full py-4 px-6 bg-green-600 hover:bg-green-700 text-white rounded-xl font-semibold text-lg flex items-center justify-center gap-3 transition-colors"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          Finish Job
        </button>
      )}

      {/* Job Details Card */}
      <div className="card">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Job Details</h2>

        <div className="space-y-4">
          <div>
            <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400">Description</h3>
            <p className="mt-1 text-slate-900 dark:text-white">{job.description}</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400">Scheduled</h3>
              <p className="mt-1 text-slate-900 dark:text-white">{formatDateTime(job.scheduledStart)}</p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400">Service Area</h3>
              <p className="mt-1 text-slate-900 dark:text-white">{job.serviceArea || 'N/A'}</p>
            </div>
          </div>

          {job.checkInAt && (
            <div className="pt-4 border-t border-slate-200 dark:border-slate-700">
              <div className="flex items-center gap-2 text-orange-600 dark:text-orange-400">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span className="font-medium">Checked in: {formatDateTime(job.checkInAt)}</span>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Location Card */}
      {job.household?.homeProfile?.address && (
        <div className="card">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Location</h2>
          <div className="flex items-start gap-3 mb-4">
            <svg className="w-5 h-5 text-slate-400 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <p className="text-slate-900 dark:text-white">{job.household.homeProfile.address}</p>
          </div>
          <button
            onClick={openInMaps}
            className="w-full py-3 px-4 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-medium flex items-center justify-center gap-2 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
            </svg>
            Open in Maps
          </button>
        </div>
      )}

      {/* Notes */}
      {(job.notes?.length || 0) > 0 && (
        <div className="card">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Notes</h2>
          <div className="space-y-3">
            {job.notes.map((note) => (
              <div key={note.id} className="p-3 rounded-lg bg-slate-50 dark:bg-slate-800">
                <p className="text-slate-900 dark:text-white">{note.body}</p>
                <p className="text-sm text-slate-500 dark:text-slate-400 mt-2">
                  {note.author.firstName} {note.author.lastName} -{' '}
                  {new Date(note.createdAt).toLocaleDateString()}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Complete Job Modal */}
      {showCompleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-slate-800 rounded-xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <h2 className="text-xl font-semibold text-slate-900 dark:text-white mb-4">Complete Job</h2>
              <p className="text-slate-600 dark:text-slate-400 mb-6">
                Upload at least one photo showing the completed work.
              </p>

              {/* Image Upload */}
              <div className="mb-6">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  multiple
                  onChange={handleImageUpload}
                  className="hidden"
                />
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="w-full py-8 border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-lg hover:border-orange-500 transition-colors flex flex-col items-center gap-2"
                >
                  <svg className="w-10 h-10 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  <span className="text-slate-600 dark:text-slate-400">Tap to upload photos</span>
                </button>
              </div>

              {/* Uploaded Images Preview */}
              {proofImages.length > 0 && (
                <div className="grid grid-cols-3 gap-2 mb-6">
                  {proofImages.map((img, index) => (
                    <div key={index} className="relative aspect-square">
                      <img
                        src={img}
                        alt={`Proof ${index + 1}`}
                        className="w-full h-full object-cover rounded-lg"
                      />
                      <button
                        onClick={() => handleRemoveImage(index)}
                        className="absolute top-1 right-1 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center"
                      >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                    </div>
                  ))}
                </div>
              )}

              {/* Completion Notes */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                  Notes (Optional)
                </label>
                <textarea
                  value={completionNotes}
                  onChange={(e) => setCompletionNotes(e.target.value)}
                  placeholder="Any additional notes about the completed work..."
                  rows={3}
                  className="w-full px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white"
                />
              </div>

              {/* Actions */}
              <div className="flex gap-3">
                <button
                  onClick={() => setShowCompleteModal(false)}
                  className="flex-1 py-3 px-4 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 rounded-lg font-medium hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleCheckOut}
                  disabled={proofImages.length === 0 || isCheckingOut}
                  className="flex-1 py-3 px-4 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                  {isCheckingOut ? (
                    <>
                      <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                      Submitting...
                    </>
                  ) : (
                    'Submit Completion'
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
