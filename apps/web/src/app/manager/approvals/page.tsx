'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import Link from 'next/link';
import {
  CheckCircle2,
  XCircle,
  Clock,
  AlertCircle,
  DollarSign,
  Calendar,
  MessageSquare,
  ChevronDown,
  ChevronUp,
  Wrench,
  Truck,
  FileText,
  AlertTriangle,
  Plus,
  Home,
  X,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type ApprovalType = 'EXPENSE' | 'VENDOR_SELECTION' | 'SCHEDULE' | 'PROJECT' | 'OTHER';
type ApprovalStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'EXPIRED' | 'CANCELLED';
type ApprovalPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT';

interface ApprovalComment {
  id: string;
  content: string;
  createdAt: string;
  author: {
    id: string;
    displayName?: string;
    firstName?: string;
    lastName?: string;
  };
}

interface ApprovalRequest {
  id: string;
  householdId: string;
  type: ApprovalType;
  priority: ApprovalPriority;
  status: ApprovalStatus;
  title: string;
  description?: string;
  amount?: string;
  vendorName?: string;
  expiresAt?: string;
  decidedAt?: string;
  decisionNote?: string;
  createdAt: string;
  household?: {
    id: string;
    name: string;
  };
  decider?: {
    id: string;
    displayName?: string;
    firstName?: string;
    lastName?: string;
  };
  comments: ApprovalComment[];
}

// ============================================================================
// HELPERS
// ============================================================================

const formatCurrency = (amount: string | number) => {
  const num = typeof amount === 'string' ? parseFloat(amount) : amount;
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(num);
};

const formatDate = (dateStr: string) => {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};

const formatTime = (dateStr: string) => {
  const date = new Date(dateStr);
  return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
};

const getDeciderName = (decider?: ApprovalRequest['decider']) => {
  if (!decider) return 'Pending';
  if (decider.displayName) return decider.displayName;
  if (decider.firstName || decider.lastName) {
    return `${decider.firstName || ''} ${decider.lastName || ''}`.trim();
  }
  return 'Homeowner';
};

const getTypeIcon = (type: ApprovalType) => {
  switch (type) {
    case 'EXPENSE': return DollarSign;
    case 'VENDOR_SELECTION': return Truck;
    case 'SCHEDULE': return Calendar;
    case 'PROJECT': return Wrench;
    default: return FileText;
  }
};

const getTypeLabel = (type: ApprovalType) => {
  switch (type) {
    case 'EXPENSE': return 'Expense';
    case 'VENDOR_SELECTION': return 'Vendor Selection';
    case 'SCHEDULE': return 'Schedule';
    case 'PROJECT': return 'Project';
    default: return 'Other';
  }
};

const getPriorityBadge = (priority: ApprovalPriority) => {
  switch (priority) {
    case 'URGENT':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-red-100 text-red-700 text-xs font-medium rounded-full">
          <AlertTriangle className="w-3 h-3" />
          Urgent
        </span>
      );
    case 'HIGH':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-orange-100 text-orange-700 text-xs font-medium rounded-full">
          High
        </span>
      );
    case 'MEDIUM':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-blue-100 text-blue-700 text-xs font-medium rounded-full">
          Normal
        </span>
      );
    case 'LOW':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-gray-100 text-gray-600 text-xs font-medium rounded-full">
          Low
        </span>
      );
  }
};

const getStatusBadge = (status: ApprovalStatus) => {
  switch (status) {
    case 'PENDING':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded-full">
          <Clock className="w-3 h-3" />
          Pending
        </span>
      );
    case 'APPROVED':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
          <CheckCircle2 className="w-3 h-3" />
          Approved
        </span>
      );
    case 'REJECTED':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-red-100 text-red-700 text-xs font-medium rounded-full">
          <XCircle className="w-3 h-3" />
          Rejected
        </span>
      );
    case 'EXPIRED':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-gray-100 text-gray-600 text-xs font-medium rounded-full">
          Expired
        </span>
      );
    case 'CANCELLED':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-gray-100 text-gray-600 text-xs font-medium rounded-full">
          Cancelled
        </span>
      );
  }
};

// ============================================================================
// COMPONENTS
// ============================================================================

function ApprovalCard({
  approval,
  onCancel,
  isExpanded,
  onToggleExpand,
}: {
  approval: ApprovalRequest;
  onCancel: (id: string) => void;
  isExpanded: boolean;
  onToggleExpand: () => void;
}) {
  const TypeIcon = getTypeIcon(approval.type);
  const isPending = approval.status === 'PENDING';

  return (
    <div
      className={`bg-white rounded-xl border transition-all ${
        isPending ? 'border-amber-200' : 'border-gray-200'
      }`}
    >
      {/* Header */}
      <div className="p-4">
        <div className="flex items-start justify-between gap-4">
          <div className="flex items-start gap-3 flex-1">
            <div className={`p-2 rounded-lg ${isPending ? 'bg-amber-100' : 'bg-gray-100'}`}>
              <TypeIcon className={`w-5 h-5 ${isPending ? 'text-amber-600' : 'text-gray-500'}`} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap mb-1">
                <h3 className="font-medium text-gray-900">{approval.title}</h3>
                {getStatusBadge(approval.status)}
                {getPriorityBadge(approval.priority)}
              </div>
              {approval.household && (
                <div className="flex items-center gap-1 text-sm text-gray-500">
                  <Home className="w-3.5 h-3.5" />
                  {approval.household.name}
                </div>
              )}
              <div className="flex items-center gap-2 text-xs text-gray-400 mt-1">
                <span>{getTypeLabel(approval.type)}</span>
                <span>&bull;</span>
                <span>{formatDate(approval.createdAt)}</span>
              </div>
            </div>
          </div>

          <div className="text-right">
            {approval.amount && (
              <div className="text-lg font-semibold text-gray-900">{formatCurrency(approval.amount)}</div>
            )}
            {approval.vendorName && (
              <div className="text-sm text-gray-500">{approval.vendorName}</div>
            )}
          </div>
        </div>

        {/* Decision info for decided approvals */}
        {!isPending && approval.decidedAt && (
          <div className="mt-3 p-3 bg-gray-50 rounded-lg">
            <div className="flex items-center justify-between text-sm">
              <span className="text-gray-500">
                {approval.status === 'APPROVED' ? 'Approved by' : 'Rejected by'} {getDeciderName(approval.decider)}
              </span>
              <span className="text-gray-400">{formatDate(approval.decidedAt)}</span>
            </div>
            {approval.decisionNote && (
              <p className="text-sm text-gray-600 mt-2">&ldquo;{approval.decisionNote}&rdquo;</p>
            )}
          </div>
        )}

        {/* Cancel button for pending */}
        {isPending && (
          <div className="mt-3 flex justify-end">
            <button
              onClick={() => onCancel(approval.id)}
              className="flex items-center gap-1.5 px-3 py-1.5 text-sm text-gray-600 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
            >
              <X className="w-4 h-4" />
              Cancel Request
            </button>
          </div>
        )}
      </div>

      {/* Expandable Details */}
      <div className="border-t border-gray-100">
        <button
          onClick={onToggleExpand}
          className="w-full flex items-center justify-center gap-2 py-2.5 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors"
        >
          {isExpanded ? 'Hide Details' : 'View Details'}
          {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
        </button>

        {isExpanded && (
          <div className="px-4 pb-4 border-t border-gray-100 space-y-3">
            {approval.description && (
              <div className="pt-3">
                <div className="text-xs font-medium text-gray-500 mb-1">Description</div>
                <p className="text-sm text-gray-700">{approval.description}</p>
              </div>
            )}

            {approval.comments.length > 0 && (
              <div className="pt-2">
                <div className="flex items-center gap-1 text-xs font-medium text-gray-500 mb-2">
                  <MessageSquare className="w-3.5 h-3.5" />
                  Comments ({approval.comments.length})
                </div>
                <div className="space-y-2">
                  {approval.comments.map((comment) => (
                    <div key={comment.id} className="flex gap-2 text-sm">
                      <div className="w-6 h-6 bg-gray-200 rounded-full flex items-center justify-center flex-shrink-0">
                        <span className="text-xs font-medium text-gray-600">
                          {(comment.author.displayName?.[0] || comment.author.firstName?.[0] || '?').toUpperCase()}
                        </span>
                      </div>
                      <div>
                        <span className="font-medium text-gray-900">
                          {comment.author.displayName || `${comment.author.firstName || ''} ${comment.author.lastName || ''}`.trim()}
                        </span>
                        <span className="text-gray-400 mx-1">&bull;</span>
                        <span className="text-gray-400 text-xs">{formatDate(comment.createdAt)}</span>
                        <p className="text-gray-600 mt-0.5">{comment.content}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

function EmptyState({ filter }: { filter: string }) {
  return (
    <div className="text-center py-12 px-4">
      <div className="w-16 h-16 mx-auto mb-4 bg-gray-100 rounded-full flex items-center justify-center">
        <FileText className="w-8 h-8 text-gray-400" />
      </div>
      <h3 className="text-lg font-semibold text-gray-900 mb-2">
        {filter === 'all' ? 'No approval requests' : `No ${filter} approvals`}
      </h3>
      <p className="text-gray-600 max-w-sm mx-auto mb-6">
        {filter === 'pending'
          ? "You don't have any pending approval requests."
          : "You haven't created any approval requests yet."}
      </p>
      <Link
        href="/manager/approvals/new"
        className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg font-medium hover:bg-emerald-700 transition-colors"
      >
        <Plus className="w-4 h-4" />
        Request Approval
      </Link>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function ManagerApprovalsPage() {
  const { token } = useAuth();
  const [approvals, setApprovals] = useState<ApprovalRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const apiUrl = process.env.NEXT_PUBLIC_API_URL || '';

  const showToast = (message: string, type: 'success' | 'error') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const fetchApprovals = useCallback(async () => {
    if (!token) return;

    try {
      setIsLoading(true);
      const status = filter === 'pending' ? 'PENDING' : filter === 'approved' ? 'APPROVED' : filter === 'rejected' ? 'REJECTED' : '';
      const url = `${apiUrl}/approvals/manager/my-requests${status ? `?status=${status}` : ''}`;
      const response = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!response.ok) throw new Error('Failed to fetch approvals');

      const data = await response.json();
      setApprovals(data);
      setError(null);
    } catch (err) {
      setError('Failed to load approvals');
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  }, [token, apiUrl, filter]);

  useEffect(() => {
    fetchApprovals();
  }, [fetchApprovals]);

  const handleCancel = async (id: string) => {
    try {
      const response = await fetch(`${apiUrl}/approvals/${id}/cancel`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) throw new Error('Failed to cancel');

      showToast('Approval request cancelled.', 'success');
      fetchApprovals();
    } catch (err) {
      showToast('Failed to cancel. Please try again.', 'error');
      console.error(err);
    }
  };

  const pendingCount = approvals.filter((a) => a.status === 'PENDING').length;
  const approvedCount = approvals.filter((a) => a.status === 'APPROVED').length;
  const rejectedCount = approvals.filter((a) => a.status === 'REJECTED').length;

  return (
    <div className="min-h-screen bg-gray-50 pb-8">
      {/* Toast Notification */}
      {toast && (
        <div className="fixed top-4 right-4 z-50 animate-slide-down">
          <div
            className={`flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg ${
              toast.type === 'success' ? 'bg-emerald-600 text-white' : 'bg-red-600 text-white'
            }`}
          >
            {toast.type === 'success' ? <CheckCircle2 className="w-5 h-5" /> : <XCircle className="w-5 h-5" />}
            <span className="font-medium">{toast.message}</span>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Approval Requests</h1>
              <p className="text-gray-600 mt-1">
                Request approvals from homeowners for expenses and decisions
              </p>
            </div>

            <Link
              href="/manager/approvals/new"
              className="flex items-center gap-2 px-4 py-2.5 bg-emerald-600 text-white rounded-lg font-medium hover:bg-emerald-700 transition-colors"
            >
              <Plus className="w-4 h-4" />
              New Request
            </Link>
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <button
            onClick={() => setFilter('all')}
            className={`p-4 rounded-xl border transition-all ${
              filter === 'all' ? 'bg-white border-emerald-500 shadow-sm' : 'bg-white border-gray-200 hover:border-gray-300'
            }`}
          >
            <div className="text-2xl font-bold text-gray-900">{approvals.length}</div>
            <div className="text-sm text-gray-500">Total</div>
          </button>
          <button
            onClick={() => setFilter('pending')}
            className={`p-4 rounded-xl border transition-all ${
              filter === 'pending' ? 'bg-white border-amber-500 shadow-sm' : 'bg-white border-gray-200 hover:border-gray-300'
            }`}
          >
            <div className="text-2xl font-bold text-amber-600">{pendingCount}</div>
            <div className="text-sm text-gray-500">Pending</div>
          </button>
          <button
            onClick={() => setFilter('approved')}
            className={`p-4 rounded-xl border transition-all ${
              filter === 'approved' ? 'bg-white border-emerald-500 shadow-sm' : 'bg-white border-gray-200 hover:border-gray-300'
            }`}
          >
            <div className="text-2xl font-bold text-emerald-600">{approvedCount}</div>
            <div className="text-sm text-gray-500">Approved</div>
          </button>
          <button
            onClick={() => setFilter('rejected')}
            className={`p-4 rounded-xl border transition-all ${
              filter === 'rejected' ? 'bg-white border-red-500 shadow-sm' : 'bg-white border-gray-200 hover:border-gray-300'
            }`}
          >
            <div className="text-2xl font-bold text-red-600">{rejectedCount}</div>
            <div className="text-sm text-gray-500">Rejected</div>
          </button>
        </div>

        {/* Content */}
        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="w-8 h-8 border-4 border-emerald-600 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : error ? (
          <div className="text-center py-12">
            <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
            <p className="text-gray-600">{error}</p>
            <button
              onClick={fetchApprovals}
              className="mt-4 px-4 py-2 bg-emerald-600 text-white rounded-lg font-medium hover:bg-emerald-700"
            >
              Try Again
            </button>
          </div>
        ) : approvals.length === 0 ? (
          <EmptyState filter={filter} />
        ) : (
          <div className="space-y-4">
            {approvals.map((approval) => (
              <ApprovalCard
                key={approval.id}
                approval={approval}
                onCancel={handleCancel}
                isExpanded={expandedId === approval.id}
                onToggleExpand={() => setExpandedId(expandedId === approval.id ? null : approval.id)}
              />
            ))}
          </div>
        )}
      </div>

      <style jsx>{`
        @keyframes slide-down {
          from {
            transform: translateY(-100%);
            opacity: 0;
          }
          to {
            transform: translateY(0);
            opacity: 1;
          }
        }
        .animate-slide-down {
          animation: slide-down 0.3s ease-out;
        }
      `}</style>
    </div>
  );
}
