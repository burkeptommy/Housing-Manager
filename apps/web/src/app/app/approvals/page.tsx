'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import {
  CheckCircle2,
  XCircle,
  Clock,
  AlertCircle,
  DollarSign,
  Calendar,
  MessageSquare,
  Send,
  ChevronDown,
  ChevronUp,
  Wrench,
  Users,
  Truck,
  FileText,
  AlertTriangle,
  Check,
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
  requester: {
    id: string;
    displayName?: string;
    firstName?: string;
    lastName?: string;
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

const getRequesterName = (requester: ApprovalRequest['requester']) => {
  if (requester.displayName) return requester.displayName;
  if (requester.firstName || requester.lastName) {
    return `${requester.firstName || ''} ${requester.lastName || ''}`.trim();
  }
  return 'Home Manager';
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
    case 'EXPENSE': return 'Expense Approval';
    case 'VENDOR_SELECTION': return 'Vendor Selection';
    case 'SCHEDULE': return 'Schedule Approval';
    case 'PROJECT': return 'Project Approval';
    default: return 'Approval Request';
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
          High Priority
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
          Low Priority
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
  onApprove,
  onReject,
  onAddComment,
  isExpanded,
  onToggleExpand,
}: {
  approval: ApprovalRequest;
  onApprove: (id: string, note?: string) => void;
  onReject: (id: string, note?: string) => void;
  onAddComment: (id: string, content: string) => void;
  isExpanded: boolean;
  onToggleExpand: () => void;
}) {
  const [decisionNote, setDecisionNote] = useState('');
  const [newComment, setNewComment] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const TypeIcon = getTypeIcon(approval.type);
  const isPending = approval.status === 'PENDING';
  const requesterName = getRequesterName(approval.requester);

  const handleApprove = async () => {
    setIsSubmitting(true);
    await onApprove(approval.id, decisionNote);
    setIsSubmitting(false);
    setDecisionNote('');
  };

  const handleReject = async () => {
    setIsSubmitting(true);
    await onReject(approval.id, decisionNote);
    setIsSubmitting(false);
    setDecisionNote('');
  };

  const handleAddComment = async () => {
    if (!newComment.trim()) return;
    await onAddComment(approval.id, newComment);
    setNewComment('');
  };

  return (
    <div
      className={`bg-white rounded-xl border-2 transition-all ${
        isPending && approval.priority === 'URGENT'
          ? 'border-red-300 shadow-lg shadow-red-100'
          : isPending && approval.priority === 'HIGH'
            ? 'border-orange-200 shadow-md'
            : isPending
              ? 'border-amber-200'
              : 'border-gray-200'
      }`}
    >
      {/* Header */}
      <div className="p-5">
        {isPending && approval.priority === 'URGENT' && (
          <div className="flex items-center gap-2 text-red-700 text-sm font-medium mb-4 -mt-1">
            <AlertCircle className="w-4 h-4" />
            Urgent - Response needed soon
          </div>
        )}

        <div className="flex items-start justify-between gap-4">
          <div className="flex items-start gap-3 flex-1">
            <div className={`p-2.5 rounded-xl ${isPending ? 'bg-amber-100' : 'bg-gray-100'}`}>
              <TypeIcon className={`w-5 h-5 ${isPending ? 'text-amber-600' : 'text-gray-500'}`} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap mb-1">
                <h3 className="font-semibold text-gray-900">{approval.title}</h3>
                {getPriorityBadge(approval.priority)}
                {getStatusBadge(approval.status)}
              </div>
              <p className="text-sm text-gray-500">
                {getTypeLabel(approval.type)} from {requesterName}
              </p>
              <p className="text-xs text-gray-400 mt-1">
                {formatDate(approval.createdAt)} at {formatTime(approval.createdAt)}
              </p>
            </div>
          </div>

          {approval.amount && (
            <div className="text-right">
              <div className="text-xl font-bold text-gray-900">{formatCurrency(approval.amount)}</div>
              {approval.vendorName && (
                <div className="text-sm text-gray-500">{approval.vendorName}</div>
              )}
            </div>
          )}
        </div>

        {approval.description && (
          <div className="mt-4 p-4 bg-emerald-50 rounded-xl border border-emerald-100">
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-emerald-200 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-sm font-semibold text-emerald-700">{requesterName[0]}</span>
              </div>
              <div>
                <div className="text-xs font-medium text-emerald-700 mb-1">Note from {requesterName}</div>
                <div className="text-sm text-gray-700">{approval.description}</div>
              </div>
            </div>
          </div>
        )}

        {/* Action Buttons (only for pending) */}
        {isPending && (
          <div className="mt-4 space-y-3">
            <textarea
              placeholder="Add a note (optional)..."
              value={decisionNote}
              onChange={(e) => setDecisionNote(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm resize-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
              rows={2}
            />
            <div className="flex gap-3">
              <button
                onClick={handleApprove}
                disabled={isSubmitting}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-emerald-600 text-white rounded-lg font-medium hover:bg-emerald-700 transition-colors disabled:opacity-50"
              >
                <Check className="w-4 h-4" />
                Approve
              </button>
              <button
                onClick={handleReject}
                disabled={isSubmitting}
                className="flex items-center justify-center gap-2 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50 transition-colors disabled:opacity-50"
              >
                <X className="w-4 h-4" />
                Reject
              </button>
            </div>
          </div>
        )}

        {/* Decision Note (for decided approvals) */}
        {!isPending && approval.decisionNote && (
          <div className="mt-4 p-3 bg-gray-50 rounded-lg">
            <div className="text-xs font-medium text-gray-500 mb-1">Decision Note</div>
            <div className="text-sm text-gray-700">{approval.decisionNote}</div>
          </div>
        )}
      </div>

      {/* Expandable Comments Section */}
      <div className="border-t border-gray-100">
        <button
          onClick={onToggleExpand}
          className="w-full flex items-center justify-center gap-2 py-3 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors"
        >
          <MessageSquare className="w-4 h-4" />
          {approval.comments.length > 0
            ? `${approval.comments.length} comment${approval.comments.length !== 1 ? 's' : ''}`
            : 'Add comment'}
          {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
        </button>

        {isExpanded && (
          <div className="px-5 pb-5 border-t border-gray-100">
            {/* Comments List */}
            {approval.comments.length > 0 && (
              <div className="space-y-3 pt-4">
                {approval.comments.map((comment) => (
                  <div key={comment.id} className="flex gap-3">
                    <div className="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center flex-shrink-0">
                      <span className="text-xs font-semibold text-gray-600">
                        {(comment.author.displayName?.[0] || comment.author.firstName?.[0] || '?').toUpperCase()}
                      </span>
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium text-gray-900">
                          {comment.author.displayName || `${comment.author.firstName || ''} ${comment.author.lastName || ''}`.trim()}
                        </span>
                        <span className="text-xs text-gray-400">{formatDate(comment.createdAt)}</span>
                      </div>
                      <p className="text-sm text-gray-600 mt-0.5">{comment.content}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Add Comment Input */}
            <div className="flex gap-2 pt-4">
              <input
                type="text"
                placeholder="Add a comment..."
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleAddComment()}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
              />
              <button
                onClick={handleAddComment}
                disabled={!newComment.trim()}
                className="px-3 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Send className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function EmptyState({ showHistory }: { showHistory: boolean }) {
  return (
    <div className="text-center py-12 px-4">
      <div className="w-16 h-16 mx-auto mb-4 bg-emerald-100 rounded-full flex items-center justify-center">
        {showHistory ? (
          <FileText className="w-8 h-8 text-emerald-600" />
        ) : (
          <CheckCircle2 className="w-8 h-8 text-emerald-600" />
        )}
      </div>
      <h3 className="text-lg font-semibold text-gray-900 mb-2">
        {showHistory ? 'No approval history' : 'All caught up!'}
      </h3>
      <p className="text-gray-600 max-w-sm mx-auto">
        {showHistory
          ? "You haven't made any approval decisions yet."
          : "You don't have any pending approvals. Your home manager will notify you when something needs your attention."}
      </p>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function ApprovalsPage() {
  const { token, householdId } = useAuth();
  const [approvals, setApprovals] = useState<ApprovalRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showHistory, setShowHistory] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const apiUrl = process.env.NEXT_PUBLIC_API_URL || '';

  const showToast = (message: string, type: 'success' | 'error') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const fetchApprovals = useCallback(async () => {
    if (!token || !householdId) return;

    try {
      setIsLoading(true);
      const status = showHistory ? '' : 'PENDING';
      const url = `${apiUrl}/approvals/household/${householdId}${status ? `?status=${status}` : ''}`;
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
  }, [token, householdId, apiUrl, showHistory]);

  useEffect(() => {
    fetchApprovals();
  }, [fetchApprovals]);

  const handleApprove = async (id: string, note?: string) => {
    try {
      const response = await fetch(`${apiUrl}/approvals/${id}/decide`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status: 'APPROVED', decisionNote: note }),
      });

      if (!response.ok) throw new Error('Failed to approve');

      showToast('Approved! Your home manager has been notified.', 'success');
      fetchApprovals();
    } catch (err) {
      showToast('Failed to approve. Please try again.', 'error');
      console.error(err);
    }
  };

  const handleReject = async (id: string, note?: string) => {
    try {
      const response = await fetch(`${apiUrl}/approvals/${id}/decide`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status: 'REJECTED', decisionNote: note }),
      });

      if (!response.ok) throw new Error('Failed to reject');

      showToast('Rejected. Your home manager has been notified.', 'success');
      fetchApprovals();
    } catch (err) {
      showToast('Failed to reject. Please try again.', 'error');
      console.error(err);
    }
  };

  const handleAddComment = async (id: string, content: string) => {
    try {
      const response = await fetch(`${apiUrl}/approvals/${id}/comments`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ content }),
      });

      if (!response.ok) throw new Error('Failed to add comment');

      fetchApprovals();
    } catch (err) {
      showToast('Failed to add comment. Please try again.', 'error');
      console.error(err);
    }
  };

  const pendingCount = approvals.filter((a) => a.status === 'PENDING').length;

  return (
    <div className="min-h-screen bg-gray-50 pb-24 lg:pb-8">
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
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Approvals</h1>
              <p className="text-gray-600 mt-1">
                {pendingCount > 0
                  ? `${pendingCount} item${pendingCount !== 1 ? 's' : ''} awaiting your decision`
                  : 'Review and approve requests from your home manager'}
              </p>
            </div>

            {/* Toggle */}
            <div className="flex items-center gap-2 bg-gray-100 rounded-lg p-1">
              <button
                onClick={() => setShowHistory(false)}
                className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                  !showHistory ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                Pending
                {pendingCount > 0 && (
                  <span className="ml-2 px-1.5 py-0.5 bg-amber-500 text-white text-xs font-semibold rounded-full">
                    {pendingCount}
                  </span>
                )}
              </button>
              <button
                onClick={() => setShowHistory(true)}
                className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                  showHistory ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                History
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
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
          <EmptyState showHistory={showHistory} />
        ) : (
          <div className="space-y-4">
            {approvals.map((approval) => (
              <ApprovalCard
                key={approval.id}
                approval={approval}
                onApprove={handleApprove}
                onReject={handleReject}
                onAddComment={handleAddComment}
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
