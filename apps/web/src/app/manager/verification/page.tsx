'use client';

import { useState, useEffect, useCallback } from 'react';
import type { VerificationQueueItem, VendorWorkOrderStatus } from '@haven/core';

// Mock data for demo
const mockQueue: VerificationQueueItem[] = [
  {
    id: 'wo-verify-1',
    title: 'Garage Door Spring Repair',
    description:
      'Replace broken torsion spring on garage door. The spring snapped and the door is currently stuck in the closed position.',
    status: 'COMPLETED',
    completedAt: '2024-12-15T12:30:00Z',
    proofImages: [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1486006920555-c77dcf18193c?w=400&h=300&fit=crop',
    ],
    actualCost: 425,
    vendor: {
      id: 'vendor-ace',
      displayName: 'Ace Roofing & Repair',
      phone: '(310) 555-1234',
      email: 'jobs@aceroofing.com',
    },
    household: {
      id: 'h-malibu',
      name: 'Malibu Mansion',
    },
    notes: [
      {
        id: 'note-1',
        body: 'Replaced torsion spring with heavy-duty model. Also lubricated all moving parts and adjusted tension. Tested door operation 10+ times.',
        createdAt: '2024-12-15T12:30:00Z',
        author: {
          firstName: 'Ace',
          lastName: 'Roofing',
        },
      },
    ],
  },
  {
    id: 'wo-verify-2',
    title: 'Pool Pump Repair',
    description: 'Pool pump making unusual noise. May need bearing replacement.',
    status: 'COMPLETED',
    completedAt: '2024-12-16T16:45:00Z',
    proofImages: [
      'https://images.unsplash.com/photo-1575429198097-0414ec08e8cd?w=400&h=300&fit=crop',
    ],
    actualCost: 325,
    vendor: {
      id: 'vendor-pool',
      displayName: 'Crystal Pool Service',
      phone: '(310) 555-5678',
      email: 'service@crystalpool.com',
    },
    household: {
      id: 'h-beverly',
      name: 'Beverly Hills Estate',
    },
    notes: [
      {
        id: 'note-2',
        body: 'Replaced pump bearings and motor seal. Pump now running quietly.',
        createdAt: '2024-12-16T16:45:00Z',
        author: {
          firstName: 'Crystal',
          lastName: 'Pool',
        },
      },
    ],
  },
];

export default function VerificationQueuePage() {
  const [queue, setQueue] = useState<VerificationQueueItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedJob, setSelectedJob] = useState<VerificationQueueItem | null>(null);
  const [isApproving, setIsApproving] = useState(false);
  const [isRejecting, setIsRejecting] = useState(false);
  const [revisionReason, setRevisionReason] = useState('');
  const [showRevisionModal, setShowRevisionModal] = useState(false);

  const loadQueue = useCallback(async () => {
    setIsLoading(true);
    await new Promise((resolve) => setTimeout(resolve, 500));
    setQueue(mockQueue);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    loadQueue();
  }, [loadQueue]);

  const handleApprove = async (jobId: string) => {
    setIsApproving(true);
    await new Promise((resolve) => setTimeout(resolve, 1000));
    setQueue((prev) => prev.filter((j) => j.id !== jobId));
    setSelectedJob(null);
    setIsApproving(false);
  };

  const handleRequestRevision = async (jobId: string) => {
    if (!revisionReason.trim()) return;
    setIsRejecting(true);
    await new Promise((resolve) => setTimeout(resolve, 1000));
    setQueue((prev) => prev.filter((j) => j.id !== jobId));
    setSelectedJob(null);
    setShowRevisionModal(false);
    setRevisionReason('');
    setIsRejecting(false);
  };

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return 'N/A';
    return new Date(dateStr).toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const formatCurrency = (amount: number | null) => {
    if (amount === null) return 'N/A';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

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
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Verification Queue</h1>
        <p className="text-slate-600 dark:text-slate-400">
          Review and approve completed vendor work
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
              <svg
                className="w-6 h-6 text-blue-600 dark:text-blue-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{queue.length}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Pending Review</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
              <svg
                className="w-6 h-6 text-green-600 dark:text-green-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(queue.reduce((sum, j) => sum + (j.actualCost || 0), 0))}
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Total Value</p>
            </div>
          </div>
        </div>
        <div className="card hidden lg:block">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
              <svg
                className="w-6 h-6 text-purple-600 dark:text-purple-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5"
                />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {new Set(queue.map((j) => j.vendor?.id)).size}
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Vendors</p>
            </div>
          </div>
        </div>
      </div>

      {/* Split View */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Queue List */}
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Jobs Awaiting Review</h2>
          {queue.length === 0 ? (
            <div className="card text-center py-12">
              <svg
                className="w-12 h-12 mx-auto text-slate-400 mb-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">All caught up!</h3>
              <p className="text-slate-600 dark:text-slate-400">No jobs pending verification.</p>
            </div>
          ) : (
            queue.map((job) => (
              <button
                key={job.id}
                onClick={() => setSelectedJob(job)}
                className={`card w-full text-left transition-all ${
                  selectedJob?.id === job.id
                    ? 'ring-2 ring-emerald-500 border-emerald-500'
                    : 'hover:shadow-lg'
                }`}
              >
                <div className="flex items-start gap-4">
                  <div className="w-16 h-16 rounded-lg bg-slate-100 dark:bg-slate-700 overflow-hidden flex-shrink-0">
                    {job.proofImages[0] ? (
                      <img
                        src={job.proofImages[0]}
                        alt="Proof"
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <svg
                          className="w-8 h-8 text-slate-400"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                          />
                        </svg>
                      </div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-slate-900 dark:text-white truncate">{job.title}</h3>
                    <p className="text-sm text-slate-500 dark:text-slate-400">{job.vendor?.displayName}</p>
                    <div className="flex items-center gap-3 mt-1 text-sm text-slate-500 dark:text-slate-400">
                      <span>{job.household.name}</span>
                      <span>|</span>
                      <span>{formatDate(job.completedAt)}</span>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="font-bold text-slate-900 dark:text-white">{formatCurrency(job.actualCost)}</p>
                    <p className="text-xs text-slate-500 dark:text-slate-400">
                      {job.proofImages.length} photo{job.proofImages.length !== 1 ? 's' : ''}
                    </p>
                  </div>
                </div>
              </button>
            ))
          )}
        </div>

        {/* Detail View */}
        <div className="lg:sticky lg:top-6">
          {selectedJob ? (
            <div className="card">
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Job Details</h2>

              {/* Job Info */}
              <div className="mb-6">
                <h3 className="font-semibold text-slate-900 dark:text-white">{selectedJob.title}</h3>
                <p className="text-sm text-slate-600 dark:text-slate-400 mt-1">{selectedJob.description}</p>
              </div>

              {/* Proof Images */}
              <div className="mb-6">
                <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-2">Proof Photos</h4>
                <div className="grid grid-cols-2 gap-2">
                  {selectedJob.proofImages.map((img, index) => (
                    <a
                      key={index}
                      href={img}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="aspect-video rounded-lg overflow-hidden hover:opacity-80 transition-opacity"
                    >
                      <img src={img} alt={`Proof ${index + 1}`} className="w-full h-full object-cover" />
                    </a>
                  ))}
                </div>
              </div>

              {/* Vendor Notes */}
              {selectedJob.notes.length > 0 && (
                <div className="mb-6">
                  <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-2">Vendor Notes</h4>
                  {selectedJob.notes.map((note) => (
                    <div key={note.id} className="p-3 rounded-lg bg-slate-50 dark:bg-slate-800">
                      <p className="text-slate-900 dark:text-white">{note.body}</p>
                      <p className="text-sm text-slate-500 dark:text-slate-400 mt-2">
                        {note.author.firstName} {note.author.lastName} - {formatDate(note.createdAt)}
                      </p>
                    </div>
                  ))}
                </div>
              )}

              {/* Vendor & Property Info */}
              <div className="grid grid-cols-2 gap-4 mb-6">
                <div>
                  <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Vendor</h4>
                  <p className="text-slate-900 dark:text-white">{selectedJob.vendor?.displayName}</p>
                  {selectedJob.vendor?.phone && (
                    <p className="text-sm text-slate-500 dark:text-slate-400">{selectedJob.vendor.phone}</p>
                  )}
                </div>
                <div>
                  <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Property</h4>
                  <p className="text-slate-900 dark:text-white">{selectedJob.household.name}</p>
                </div>
              </div>

              {/* Cost */}
              <div className="p-4 rounded-lg bg-slate-50 dark:bg-slate-800 mb-6">
                <div className="flex justify-between items-center">
                  <span className="text-slate-600 dark:text-slate-400">Final Cost</span>
                  <span className="text-xl font-bold text-slate-900 dark:text-white">
                    {formatCurrency(selectedJob.actualCost)}
                  </span>
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-3">
                <button
                  onClick={() => setShowRevisionModal(true)}
                  className="flex-1 py-3 px-4 border border-red-300 dark:border-red-700 text-red-600 dark:text-red-400 rounded-lg font-medium hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                >
                  Request Revision
                </button>
                <button
                  onClick={() => handleApprove(selectedJob.id)}
                  disabled={isApproving}
                  className="flex-1 py-3 px-4 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {isApproving ? (
                    <>
                      <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                      Approving...
                    </>
                  ) : (
                    <>
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                      Approve
                    </>
                  )}
                </button>
              </div>
            </div>
          ) : (
            <div className="card text-center py-12">
              <svg
                className="w-12 h-12 mx-auto text-slate-400 mb-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                />
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                />
              </svg>
              <p className="text-slate-600 dark:text-slate-400">Select a job to review details</p>
            </div>
          )}
        </div>
      </div>

      {/* Revision Modal */}
      {showRevisionModal && selectedJob && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-slate-800 rounded-xl shadow-xl max-w-md w-full">
            <div className="p-6">
              <h2 className="text-xl font-semibold text-slate-900 dark:text-white mb-2">Request Revision</h2>
              <p className="text-slate-600 dark:text-slate-400 mb-4">
                Explain what needs to be fixed or improved.
              </p>
              <textarea
                value={revisionReason}
                onChange={(e) => setRevisionReason(e.target.value)}
                placeholder="Describe what changes are needed..."
                rows={4}
                className="w-full px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white mb-4"
              />
              <div className="flex gap-3">
                <button
                  onClick={() => {
                    setShowRevisionModal(false);
                    setRevisionReason('');
                  }}
                  className="flex-1 py-2.5 px-4 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 rounded-lg font-medium hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => handleRequestRevision(selectedJob.id)}
                  disabled={!revisionReason.trim() || isRejecting}
                  className="flex-1 py-2.5 px-4 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {isRejecting ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                      Sending...
                    </>
                  ) : (
                    'Send Revision Request'
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
