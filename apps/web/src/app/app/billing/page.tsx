'use client';

import { useState, useMemo, useCallback } from 'react';
import {
  CheckCircle2,
  XCircle,
  Clock,
  AlertTriangle,
  Zap,
  Wrench,
  Sparkles,
  Home,
  ShieldCheck,
  ChevronRight,
  ChevronDown,
  Receipt,
  Download,
  X,
  Check,
  AlertCircle,
  Building2,
  FileText,
  Calendar,
  Plus,
  Settings,
  TrendingUp,
  CreditCard,
  RefreshCw,
  Lightbulb,
  DollarSign,
  ArrowRight,
  CalendarDays,
  Wallet,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type TransactionStatus = 'completed' | 'pending' | 'failed' | 'requires_approval';
type TransactionCategory = 'utilities' | 'maintenance' | 'services' | 'projects' | 'insurance' | 'membership' | 'other';

interface BillItem {
  id: string;
  vendor: string;
  description: string;
  amount: number;
  category: TransactionCategory;
  status: TransactionStatus;
  date: Date;
  receiptUrl?: string;
  isRecurring?: boolean;
  dueDate?: Date;
}

interface AuthorizationRequest {
  id: string;
  vendor: string;
  description: string;
  amount: number;
  category: TransactionCategory;
  date: Date;
  urgency: 'low' | 'medium' | 'high';
  managerNote: string;
  managerName: string;
}

interface UpcomingBill {
  id: string;
  vendor: string;
  amount: number;
  dueDate: Date;
  category: TransactionCategory;
  isEstimate?: boolean;
}

interface BillAccount {
  id: string;
  vendor: string;
  accountNumber: string;
  isAutoPay: boolean;
  category: TransactionCategory;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const HAVEN_MEMBERSHIP_FEE = 149;

const generateMockBills = (): BillItem[] => {
  const now = new Date();
  const thisMonth = now.getMonth();
  const thisYear = now.getFullYear();

  return [
    // Membership (Haven's fee)
    {
      id: 'bill-0',
      vendor: 'Haven Home Management',
      description: 'Monthly membership',
      amount: HAVEN_MEMBERSHIP_FEE,
      category: 'membership',
      status: 'completed',
      date: new Date(thisYear, thisMonth, 1),
      isRecurring: true,
    },
    // Utilities - auto-paid
    {
      id: 'bill-1',
      vendor: 'Power & Light Co.',
      description: 'Electric bill',
      amount: 187.43,
      category: 'utilities',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 3),
      isRecurring: true,
      receiptUrl: '/receipts/power-dec.pdf',
    },
    {
      id: 'bill-2',
      vendor: 'City Water Authority',
      description: 'Water & sewer',
      amount: 94.50,
      category: 'utilities',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 5),
      isRecurring: true,
    },
    {
      id: 'bill-3',
      vendor: 'Gas Company',
      description: 'Natural gas',
      amount: 78.50,
      category: 'utilities',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 8),
      isRecurring: true,
    },
    {
      id: 'bill-4',
      vendor: 'Internet Plus',
      description: 'Fiber internet',
      amount: 89.99,
      category: 'utilities',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 10),
      isRecurring: true,
    },
    // Insurance
    {
      id: 'bill-5',
      vendor: 'SafeHome Insurance',
      description: 'Homeowners premium',
      amount: 312,
      category: 'insurance',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 10),
      isRecurring: true,
    },
    // Services - auto-paid recurring
    {
      id: 'bill-6',
      vendor: 'Green Thumb Landscaping',
      description: 'Monthly lawn care',
      amount: 175,
      category: 'services',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 7),
      isRecurring: true,
    },
    {
      id: 'bill-7',
      vendor: 'Pool Masters',
      description: 'Pool maintenance',
      amount: 85,
      category: 'services',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 6),
      isRecurring: true,
    },
    {
      id: 'bill-8',
      vendor: 'CleanPro Services',
      description: 'Bi-weekly cleaning',
      amount: 180,
      category: 'services',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 12),
      isRecurring: true,
    },
    // Maintenance - one-time
    {
      id: 'bill-9',
      vendor: 'HandyPro Services',
      description: 'Garbage disposal replacement',
      amount: 195,
      category: 'maintenance',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 14),
      receiptUrl: '/receipts/handypro.pdf',
    },
    {
      id: 'bill-10',
      vendor: 'HVAC Solutions',
      description: 'Annual AC tune-up',
      amount: 149,
      category: 'maintenance',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 18),
    },
  ];
};

const generateAuthorizationRequests = (): AuthorizationRequest[] => {
  const now = new Date();
  const thisMonth = now.getMonth();
  const thisYear = now.getFullYear();

  return [
    {
      id: 'auth-1',
      vendor: 'Emergency Plumbing Co.',
      description: 'Emergency pipe burst repair - Kitchen',
      amount: 450,
      category: 'maintenance',
      date: new Date(thisYear, thisMonth, now.getDate(), 14, 30),
      urgency: 'high',
      managerNote: 'Urgent - Water damage prevention. Vendor is on-site waiting for approval. I recommend approving immediately to prevent further damage.',
      managerName: 'Steve',
    },
    {
      id: 'auth-2',
      vendor: 'Ace Roofing Co.',
      description: 'Roof inspection and shingle replacement',
      amount: 875,
      category: 'maintenance',
      date: new Date(thisYear, thisMonth, now.getDate() - 1, 10, 0),
      urgency: 'medium',
      managerNote: 'Recommended after last storm. I obtained 3 quotes - this is the best value. Happy to discuss alternatives if you prefer.',
      managerName: 'Steve',
    },
  ];
};

const generateUpcomingBills = (): UpcomingBill[] => {
  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  return [
    { id: 'up-1', vendor: 'Power & Light Co.', amount: 195, dueDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 15), category: 'utilities', isEstimate: true },
    { id: 'up-2', vendor: 'City Water Authority', amount: 94.50, dueDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 10), category: 'utilities' },
    { id: 'up-3', vendor: 'SafeHome Insurance', amount: 312, dueDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 1), category: 'insurance' },
    { id: 'up-4', vendor: 'Green Thumb Landscaping', amount: 175, dueDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 7), category: 'services' },
  ];
};

const mockBillAccounts: BillAccount[] = [
  { id: 'acc-1', vendor: 'Power & Light Co.', accountNumber: '****4521', isAutoPay: true, category: 'utilities' },
  { id: 'acc-2', vendor: 'City Water Authority', accountNumber: '****7832', isAutoPay: true, category: 'utilities' },
  { id: 'acc-3', vendor: 'Gas Company', accountNumber: '****1156', isAutoPay: true, category: 'utilities' },
  { id: 'acc-4', vendor: 'Internet Plus', accountNumber: '****9044', isAutoPay: true, category: 'utilities' },
  { id: 'acc-5', vendor: 'SafeHome Insurance', accountNumber: 'POL-88721', isAutoPay: true, category: 'insurance' },
];

// ============================================================================
// HELPERS
// ============================================================================

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(amount);
};

const formatDate = (date: Date) => {
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};

const formatFullDate = (date: Date) => {
  return date.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
};

const getCategoryIcon = (category: TransactionCategory) => {
  switch (category) {
    case 'utilities': return Zap;
    case 'maintenance': return Wrench;
    case 'services': return Sparkles;
    case 'projects': return Home;
    case 'insurance': return ShieldCheck;
    case 'membership': return Receipt;
    default: return DollarSign;
  }
};

const getCategoryColor = (category: TransactionCategory) => {
  switch (category) {
    case 'utilities': return { bg: 'bg-amber-100', text: 'text-amber-700', icon: 'text-amber-600', light: 'bg-amber-50' };
    case 'maintenance': return { bg: 'bg-blue-100', text: 'text-blue-700', icon: 'text-blue-600', light: 'bg-blue-50' };
    case 'services': return { bg: 'bg-purple-100', text: 'text-purple-700', icon: 'text-purple-600', light: 'bg-purple-50' };
    case 'projects': return { bg: 'bg-rose-100', text: 'text-rose-700', icon: 'text-rose-600', light: 'bg-rose-50' };
    case 'insurance': return { bg: 'bg-emerald-100', text: 'text-emerald-700', icon: 'text-emerald-600', light: 'bg-emerald-50' };
    case 'membership': return { bg: 'bg-slate-100', text: 'text-slate-700', icon: 'text-slate-600', light: 'bg-slate-50' };
    default: return { bg: 'bg-slate-100', text: 'text-slate-700', icon: 'text-slate-600', light: 'bg-slate-50' };
  }
};

const getCategoryLabel = (category: TransactionCategory) => {
  switch (category) {
    case 'utilities': return 'Utilities';
    case 'maintenance': return 'Maintenance';
    case 'services': return 'Services';
    case 'projects': return 'Projects';
    case 'insurance': return 'Insurance';
    case 'membership': return 'Membership';
    default: return 'Other';
  }
};

// ============================================================================
// COMPONENTS
// ============================================================================

function ConfettiEffect({ show }: { show: boolean }) {
  if (!show) return null;

  return (
    <div className="fixed inset-0 pointer-events-none z-50 overflow-hidden">
      {[...Array(50)].map((_, i) => (
        <div
          key={i}
          className="absolute animate-confetti"
          style={{
            left: `${Math.random() * 100}%`,
            top: '-10px',
            animationDelay: `${Math.random() * 0.5}s`,
            animationDuration: `${2 + Math.random() * 2}s`,
          }}
        >
          <div
            className="w-3 h-3 rounded-sm"
            style={{
              backgroundColor: ['#10b981', '#f59e0b', '#3b82f6', '#ec4899', '#8b5cf6'][
                Math.floor(Math.random() * 5)
              ],
              transform: `rotate(${Math.random() * 360}deg)`,
            }}
          />
        </div>
      ))}
    </div>
  );
}

function AuthorizationCard({
  request,
  onApprove,
  onDecline,
}: {
  request: AuthorizationRequest;
  onApprove: (id: string) => void;
  onDecline: (id: string) => void;
}) {
  const CategoryIcon = getCategoryIcon(request.category);
  const categoryColor = getCategoryColor(request.category);

  return (
    <div
      className={`bg-white rounded-xl border-2 p-5 transition-all hover:shadow-lg ${
        request.urgency === 'high' ? 'border-red-200 bg-red-50/30' : 'border-slate-200'
      }`}
    >
      {/* Urgency Banner */}
      {request.urgency === 'high' && (
        <div className="flex items-center gap-2 text-red-700 text-sm font-medium mb-4 -mt-1">
          <AlertCircle className="w-4 h-4" />
          Urgent - Vendor waiting for response
        </div>
      )}

      <div className="flex items-start justify-between mb-4">
        <div className="flex items-start gap-3">
          <div className={`p-2.5 rounded-xl ${categoryColor.bg}`}>
            <CategoryIcon className={`w-5 h-5 ${categoryColor.icon}`} />
          </div>
          <div>
            <div className="font-semibold text-slate-900">{request.vendor}</div>
            <div className="text-sm text-slate-500">{request.description}</div>
          </div>
        </div>
        <div className="text-right">
          <div className="text-xl font-bold text-slate-900">{formatCurrency(request.amount)}</div>
        </div>
      </div>

      {/* Manager Note */}
      <div className="mb-4 p-4 bg-emerald-50 rounded-xl border border-emerald-100">
        <div className="flex items-start gap-3">
          <div className="w-8 h-8 bg-emerald-200 rounded-full flex items-center justify-center flex-shrink-0">
            <span className="text-sm font-semibold text-emerald-700">{request.managerName[0]}</span>
          </div>
          <div>
            <div className="text-xs font-medium text-emerald-700 mb-1">Note from {request.managerName}, your Home Manager</div>
            <div className="text-sm text-slate-700">{request.managerNote}</div>
          </div>
        </div>
      </div>

      <div className="flex gap-3">
        <button
          onClick={() => onApprove(request.id)}
          className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-emerald-600 text-white rounded-lg font-medium hover:bg-emerald-700 transition-colors"
        >
          <Check className="w-4 h-4" />
          Authorize
        </button>
        <button
          onClick={() => onDecline(request.id)}
          className="flex items-center justify-center gap-2 px-4 py-2.5 border border-slate-300 text-slate-700 rounded-lg font-medium hover:bg-slate-50 transition-colors"
        >
          <X className="w-4 h-4" />
          Decline
        </button>
      </div>
    </div>
  );
}

function BillCategoryGroup({
  category,
  bills,
  isExpanded,
  onToggle,
}: {
  category: TransactionCategory;
  bills: BillItem[];
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const CategoryIcon = getCategoryIcon(category);
  const categoryColor = getCategoryColor(category);
  const total = bills.reduce((sum, bill) => sum + bill.amount, 0);

  return (
    <div className="bg-white rounded-xl border border-slate-200">
      <button
        onClick={onToggle}
        className="w-full flex items-center justify-between p-4 hover:bg-slate-50 transition-colors rounded-xl"
      >
        <div className="flex items-center gap-3">
          <div className={`p-2 rounded-lg ${categoryColor.bg}`}>
            <CategoryIcon className={`w-5 h-5 ${categoryColor.icon}`} />
          </div>
          <div className="text-left">
            <div className="font-medium text-slate-900">{getCategoryLabel(category)}</div>
            <div className="text-sm text-slate-500">{bills.length} {bills.length === 1 ? 'item' : 'items'}</div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <span className="font-semibold text-slate-900">{formatCurrency(total)}</span>
          <ChevronDown className={`w-5 h-5 text-slate-400 transition-transform ${isExpanded ? 'rotate-180' : ''}`} />
        </div>
      </button>

      {isExpanded && (
        <div className="px-4 pb-4 space-y-2">
          {bills.map((bill) => (
            <div
              key={bill.id}
              className={`flex items-center justify-between p-3 rounded-lg ${categoryColor.light}`}
            >
              <div className="flex items-center gap-3">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-slate-900">{bill.vendor}</span>
                    {bill.isRecurring && (
                      <span className="px-1.5 py-0.5 text-[10px] font-medium bg-slate-200 text-slate-600 rounded">
                        Auto
                      </span>
                    )}
                  </div>
                  <div className="text-sm text-slate-500">{bill.description}</div>
                </div>
              </div>
              <div className="text-right">
                <div className="font-medium text-slate-900">{formatCurrency(bill.amount)}</div>
                <div className="text-xs text-slate-400">Paid {formatDate(bill.date)}</div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function BillingPage() {
  const [bills] = useState<BillItem[]>(generateMockBills);
  const [authRequests, setAuthRequests] = useState<AuthorizationRequest[]>(generateAuthorizationRequests);
  const [upcomingBills] = useState<UpcomingBill[]>(generateUpcomingBills);
  const [billAccounts] = useState<BillAccount[]>(mockBillAccounts);

  const [showConfetti, setShowConfetti] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);
  const [showStatementModal, setShowStatementModal] = useState(false);
  const [showThresholdModal, setShowThresholdModal] = useState(false);
  const [showAddAccountModal, setShowAddAccountModal] = useState(false);
  const [trustThreshold, setTrustThreshold] = useState(200);
  const [tempThreshold, setTempThreshold] = useState(200);

  // Category expansion state
  const [expandedCategories, setExpandedCategories] = useState<Set<TransactionCategory>>(new Set(['utilities']));

  // Toast helper
  const showToast = (message: string, type: 'success' | 'error' | 'info' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  // Handle authorization
  const handleApprove = useCallback((id: string) => {
    setAuthRequests((prev) => prev.filter((req) => req.id !== id));
    setShowConfetti(true);
    setTimeout(() => setShowConfetti(false), 2500);
    showToast('Authorized! Your manager will proceed.', 'success');
  }, []);

  const handleDecline = useCallback((id: string) => {
    setAuthRequests((prev) => prev.filter((req) => req.id !== id));
    showToast('Declined. Your manager has been notified.', 'info');
  }, []);

  // Toggle category expansion
  const toggleCategory = (category: TransactionCategory) => {
    setExpandedCategories((prev) => {
      const next = new Set(prev);
      if (next.has(category)) {
        next.delete(category);
      } else {
        next.add(category);
      }
      return next;
    });
  };

  // Save threshold
  const saveThreshold = () => {
    setTrustThreshold(tempThreshold);
    setShowThresholdModal(false);
    showToast(`Auto-approval threshold set to ${formatCurrency(tempThreshold)}`, 'success');
  };

  // Computed values
  const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

  const statementBreakdown = useMemo(() => {
    const membership = bills.filter(b => b.category === 'membership').reduce((s, b) => s + b.amount, 0);
    const utilities = bills.filter(b => b.category === 'utilities').reduce((s, b) => s + b.amount, 0);
    const insurance = bills.filter(b => b.category === 'insurance').reduce((s, b) => s + b.amount, 0);
    const billsPaid = utilities + insurance;
    const services = bills.filter(b => ['services', 'maintenance', 'projects'].includes(b.category)).reduce((s, b) => s + b.amount, 0);

    return { membership, billsPaid, services, total: membership + billsPaid + services };
  }, [bills]);

  const billsByCategory = useMemo(() => {
    const grouped: Record<TransactionCategory, BillItem[]> = {
      utilities: [],
      maintenance: [],
      services: [],
      projects: [],
      insurance: [],
      membership: [],
      other: [],
    };
    bills.forEach((bill) => {
      if (bill.category !== 'membership') {
        grouped[bill.category].push(bill);
      }
    });
    return grouped;
  }, [bills]);

  const nextPaymentDate = useMemo(() => {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth() + 1, 1);
  }, []);

  const daysUntilDue = useMemo(() => {
    const now = new Date();
    return Math.ceil((nextPaymentDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  }, [nextPaymentDate]);

  return (
    <div className="min-h-screen bg-slate-50 pb-24 lg:pb-8">
      <ConfettiEffect show={showConfetti} />

      {/* Toast Notification */}
      {toast && (
        <div className="fixed top-4 right-4 z-50 animate-slide-down">
          <div
            className={`flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg ${
              toast.type === 'success'
                ? 'bg-emerald-600 text-white'
                : toast.type === 'error'
                  ? 'bg-red-600 text-white'
                  : 'bg-slate-800 text-white'
            }`}
          >
            {toast.type === 'success' && <CheckCircle2 className="w-5 h-5" />}
            {toast.type === 'error' && <XCircle className="w-5 h-5" />}
            {toast.type === 'info' && <AlertCircle className="w-5 h-5" />}
            <span className="font-medium">{toast.message}</span>
          </div>
        </div>
      )}

      {/* Hero Statement Section */}
      <div className="bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 lg:py-12">
          <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-8">
            {/* Left: Statement Info */}
            <div>
              <div className="flex items-center gap-2 text-emerald-400 text-sm font-medium mb-2">
                <Receipt className="w-4 h-4" />
                Your {currentMonth} Statement
              </div>
              <h1 className="text-4xl lg:text-5xl font-bold mb-2">
                {formatCurrency(statementBreakdown.total)}
              </h1>
              <p className="text-slate-400 mb-6">
                Due {formatFullDate(nextPaymentDate)} • {daysUntilDue} days
              </p>

              {/* Breakdown */}
              <div className="space-y-3 mb-6">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-slate-300">Haven Membership</span>
                  <span className="font-medium">{formatCurrency(statementBreakdown.membership)}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-slate-300">Bills Paid on Your Behalf</span>
                  <span className="font-medium">{formatCurrency(statementBreakdown.billsPaid)}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-slate-300">Services This Month</span>
                  <span className="font-medium">{formatCurrency(statementBreakdown.services)}</span>
                </div>
                <div className="border-t border-slate-700 pt-3 flex items-center justify-between font-semibold">
                  <span>Total Due</span>
                  <span className="text-emerald-400">{formatCurrency(statementBreakdown.total)}</span>
                </div>
              </div>

              <div className="flex flex-wrap gap-3">
                <button
                  onClick={() => setShowStatementModal(true)}
                  className="flex items-center gap-2 px-5 py-2.5 bg-white text-slate-900 rounded-lg font-medium hover:bg-slate-100 transition-colors"
                >
                  <FileText className="w-4 h-4" />
                  View Full Statement
                </button>
                <button
                  onClick={() => showToast('Downloading PDF statement...', 'info')}
                  className="flex items-center gap-2 px-5 py-2.5 border border-slate-600 text-white rounded-lg font-medium hover:bg-slate-800 transition-colors"
                >
                  <Download className="w-4 h-4" />
                  Download PDF
                </button>
              </div>
            </div>

            {/* Right: Auto-pay Status */}
            <div className="bg-white/10 backdrop-blur rounded-2xl p-6 lg:w-80">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 bg-emerald-500/20 rounded-lg">
                  <RefreshCw className="w-5 h-5 text-emerald-400" />
                </div>
                <div>
                  <div className="font-semibold">Auto-Pay Enabled</div>
                  <div className="text-sm text-slate-400">Scheduled for {formatDate(nextPaymentDate)}</div>
                </div>
              </div>

              <div className="p-3 bg-slate-800/50 rounded-lg mb-4">
                <div className="flex items-center gap-3">
                  <Building2 className="w-5 h-5 text-slate-400" />
                  <div className="flex-1">
                    <div className="text-sm font-medium">Chase Checking</div>
                    <div className="text-xs text-slate-400">•••• 9876</div>
                  </div>
                  <span className="px-2 py-0.5 bg-emerald-500/20 text-emerald-400 text-xs font-medium rounded">
                    Default
                  </span>
                </div>
              </div>

              <p className="text-xs text-slate-400">
                You don&apos;t need to do anything. Haven will charge your account automatically.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Manager Authorization */}
            {authRequests.length > 0 && (
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <h2 className="text-lg font-semibold text-slate-900">Your Manager Needs Authorization</h2>
                    <span className="px-2 py-0.5 bg-orange-100 text-orange-700 text-xs font-semibold rounded-full">
                      {authRequests.length}
                    </span>
                  </div>
                  <button
                    onClick={() => {
                      setTempThreshold(trustThreshold);
                      setShowThresholdModal(true);
                    }}
                    className="text-sm text-emerald-600 hover:text-emerald-700 font-medium flex items-center gap-1"
                  >
                    <Settings className="w-4 h-4" />
                    Set Trust Threshold
                  </button>
                </div>

                <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl mb-4">
                  <div className="flex items-start gap-3">
                    <Lightbulb className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
                    <div>
                      <p className="text-sm text-amber-800">
                        <strong>These are exceptions, not routine bills.</strong> Your manager handles day-to-day expenses automatically.
                        Items here exceed your auto-approval threshold of <strong>{formatCurrency(trustThreshold)}</strong>.
                      </p>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 gap-4">
                  {authRequests.map((req) => (
                    <AuthorizationCard
                      key={req.id}
                      request={req}
                      onApprove={handleApprove}
                      onDecline={handleDecline}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* What Haven Paid This Month */}
            <div>
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                  <h2 className="text-lg font-semibold text-slate-900">What Haven Paid This Month</h2>
                </div>
                <span className="text-sm text-slate-500">
                  {bills.filter(b => b.category !== 'membership').length} items • {formatCurrency(statementBreakdown.billsPaid + statementBreakdown.services)}
                </span>
              </div>

              <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl mb-4">
                <p className="text-sm text-emerald-800">
                  <strong>You didn&apos;t have to do anything.</strong> Haven automatically paid these bills and coordinated these services for you.
                </p>
              </div>

              <div className="space-y-3">
                {Object.entries(billsByCategory)
                  .filter(([, categoryBills]) => categoryBills.length > 0)
                  .map(([category, categoryBills]) => (
                    <BillCategoryGroup
                      key={category}
                      category={category as TransactionCategory}
                      bills={categoryBills}
                      isExpanded={expandedCategories.has(category as TransactionCategory)}
                      onToggle={() => toggleCategory(category as TransactionCategory)}
                    />
                  ))}
              </div>
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Upcoming Bills */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-slate-900">Upcoming Bills</h3>
                <CalendarDays className="w-5 h-5 text-slate-400" />
              </div>

              <div className="space-y-3">
                {upcomingBills.slice(0, 4).map((bill) => {
                  const CategoryIcon = getCategoryIcon(bill.category);
                  const categoryColor = getCategoryColor(bill.category);
                  return (
                    <div key={bill.id} className="flex items-center gap-3">
                      <div className={`p-2 rounded-lg ${categoryColor.bg}`}>
                        <CategoryIcon className={`w-4 h-4 ${categoryColor.icon}`} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-slate-900 truncate">{bill.vendor}</span>
                          {bill.isEstimate && (
                            <span className="text-[10px] text-slate-400">est.</span>
                          )}
                        </div>
                        <div className="text-xs text-slate-500">Due {formatDate(bill.dueDate)}</div>
                      </div>
                      <span className="text-sm font-medium text-slate-700">{formatCurrency(bill.amount)}</span>
                    </div>
                  );
                })}
              </div>

              <div className="mt-4 pt-4 border-t border-slate-100">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-slate-500">Est. Next Month</span>
                  <span className="font-semibold text-slate-900">
                    {formatCurrency(upcomingBills.reduce((s, b) => s + b.amount, 0) + HAVEN_MEMBERSHIP_FEE)}
                  </span>
                </div>
              </div>
            </div>

            {/* Bill Accounts */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-slate-900">Bill Accounts</h3>
                <span className="text-xs text-slate-500">{billAccounts.length} linked</span>
              </div>

              <div className="space-y-2">
                {billAccounts.slice(0, 4).map((account) => (
                  <div key={account.id} className="flex items-center justify-between p-2 hover:bg-slate-50 rounded-lg transition-colors">
                    <div className="flex items-center gap-2">
                      <span className="text-sm text-slate-700">{account.vendor}</span>
                      {account.isAutoPay && (
                        <RefreshCw className="w-3 h-3 text-emerald-500" />
                      )}
                    </div>
                    <span className="text-xs text-slate-400 font-mono">{account.accountNumber}</span>
                  </div>
                ))}
              </div>

              <button
                onClick={() => setShowAddAccountModal(true)}
                className="w-full mt-4 flex items-center justify-center gap-2 py-2.5 border-2 border-dashed border-slate-300 rounded-lg text-slate-600 hover:border-emerald-500 hover:text-emerald-600 transition-colors"
              >
                <Plus className="w-4 h-4" />
                <span className="text-sm font-medium">Add Bill Account</span>
              </button>
            </div>

            {/* Annual Summary Link */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
              <div className="flex items-center gap-3 mb-3">
                <div className="p-2 bg-purple-100 rounded-lg">
                  <TrendingUp className="w-5 h-5 text-purple-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-slate-900">Annual Summary</h3>
                  <p className="text-sm text-slate-500">2024 spending overview</p>
                </div>
              </div>

              <div className="p-3 bg-slate-50 rounded-lg mb-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-slate-600">Total 2024</span>
                  <span className="font-semibold text-slate-900">{formatCurrency(statementBreakdown.total * 11)}</span>
                </div>
              </div>

              <button
                onClick={() => showToast('Opening annual summary...', 'info')}
                className="w-full flex items-center justify-center gap-2 px-4 py-2 text-purple-600 hover:bg-purple-50 rounded-lg transition-colors font-medium text-sm"
              >
                View Full Report
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>

            {/* How It Works */}
            <div className="bg-gradient-to-br from-emerald-600 to-emerald-700 rounded-2xl p-6 text-white">
              <div className="flex items-start gap-3 mb-4">
                <div className="p-2 bg-white/20 rounded-lg">
                  <Wallet className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-semibold mb-1">One Bill, Zero Hassle</h3>
                  <p className="text-sm text-emerald-100">
                    Haven pays all your home bills and sends you one simple statement each month.
                  </p>
                </div>
              </div>
              <button
                onClick={() => showToast('Opening how it works guide...', 'info')}
                className="w-full px-4 py-2 bg-white text-emerald-700 rounded-lg text-sm font-medium hover:bg-emerald-50 transition-colors"
              >
                Learn How It Works
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Full Statement Modal */}
      {showStatementModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[85vh] overflow-hidden shadow-xl">
            <div className="flex items-center justify-between p-6 border-b border-slate-200 bg-slate-50">
              <div>
                <h2 className="text-xl font-bold text-slate-900">Your {currentMonth} Statement</h2>
                <p className="text-sm text-slate-500">Due {formatFullDate(nextPaymentDate)}</p>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => showToast('Downloading PDF...', 'info')}
                  className="px-3 py-2 text-sm font-medium text-slate-700 hover:bg-white rounded-lg transition-colors flex items-center gap-2"
                >
                  <Download className="w-4 h-4" />
                  PDF
                </button>
                <button
                  onClick={() => setShowStatementModal(false)}
                  className="p-2 hover:bg-white rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-slate-500" />
                </button>
              </div>
            </div>

            <div className="p-6 overflow-y-auto max-h-[calc(85vh-200px)]">
              {/* Membership */}
              <div className="mb-6">
                <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-3">Membership</h3>
                <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-slate-200 rounded-lg">
                      <Receipt className="w-4 h-4 text-slate-600" />
                    </div>
                    <span className="font-medium text-slate-900">Haven Home Management</span>
                  </div>
                  <span className="font-semibold text-slate-900">{formatCurrency(HAVEN_MEMBERSHIP_FEE)}</span>
                </div>
              </div>

              {/* Bills by category */}
              {Object.entries(billsByCategory)
                .filter(([, categoryBills]) => categoryBills.length > 0)
                .map(([category, categoryBills]) => {
                  const CategoryIcon = getCategoryIcon(category as TransactionCategory);
                  const categoryColor = getCategoryColor(category as TransactionCategory);
                  const categoryTotal = categoryBills.reduce((s, b) => s + b.amount, 0);

                  return (
                    <div key={category} className="mb-6">
                      <div className="flex items-center justify-between mb-3">
                        <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider">
                          {getCategoryLabel(category as TransactionCategory)}
                        </h3>
                        <span className="text-sm font-medium text-slate-700">{formatCurrency(categoryTotal)}</span>
                      </div>
                      <div className="space-y-2">
                        {categoryBills.map((bill) => (
                          <div key={bill.id} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                            <div className="flex items-center gap-3">
                              <div className={`p-2 rounded-lg ${categoryColor.bg}`}>
                                <CategoryIcon className={`w-4 h-4 ${categoryColor.icon}`} />
                              </div>
                              <div>
                                <div className="font-medium text-slate-900">{bill.vendor}</div>
                                <div className="text-sm text-slate-500">{bill.description}</div>
                              </div>
                            </div>
                            <div className="text-right">
                              <div className="font-medium text-slate-900">{formatCurrency(bill.amount)}</div>
                              <div className="text-xs text-slate-400">{formatDate(bill.date)}</div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  );
                })}
            </div>

            <div className="p-6 border-t border-slate-200 bg-slate-900 text-white rounded-b-2xl">
              <div className="flex items-center justify-between">
                <span className="font-semibold">Total Due</span>
                <span className="text-3xl font-bold">{formatCurrency(statementBreakdown.total)}</span>
              </div>
              <p className="text-sm text-slate-400 mt-2">Auto-pay scheduled for {formatFullDate(nextPaymentDate)}</p>
            </div>
          </div>
        </div>
      )}

      {/* Trust Threshold Modal */}
      {showThresholdModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-xl">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-slate-900">Auto-Approval Threshold</h2>
              <button
                onClick={() => setShowThresholdModal(false)}
                className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-slate-500" />
              </button>
            </div>

            <div className="space-y-4">
              <p className="text-slate-600">
                Your manager can automatically approve expenses under this amount without asking you first.
              </p>

              <div className="p-4 bg-slate-50 rounded-xl">
                <label className="block text-sm font-medium text-slate-700 mb-2">Threshold Amount</label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                  <input
                    type="number"
                    value={tempThreshold}
                    onChange={(e) => setTempThreshold(Number(e.target.value))}
                    className="w-full pl-10 pr-4 py-3 border border-slate-300 rounded-lg text-lg font-semibold focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                </div>
              </div>

              <div className="flex gap-2">
                {[100, 200, 500, 1000].map((amount) => (
                  <button
                    key={amount}
                    onClick={() => setTempThreshold(amount)}
                    className={`flex-1 py-2 text-sm font-medium rounded-lg transition-colors ${
                      tempThreshold === amount
                        ? 'bg-emerald-600 text-white'
                        : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                    }`}
                  >
                    ${amount}
                  </button>
                ))}
              </div>

              <div className="p-3 bg-amber-50 rounded-lg border border-amber-200">
                <p className="text-sm text-amber-800">
                  <strong>Tip:</strong> A higher threshold means fewer approval requests, but less oversight on individual expenses.
                </p>
              </div>

              <button
                onClick={saveThreshold}
                className="w-full py-3 bg-emerald-600 text-white rounded-xl font-semibold hover:bg-emerald-700 transition-colors"
              >
                Save Threshold
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Bill Account Modal */}
      {showAddAccountModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-xl">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-slate-900">Add Bill Account</h2>
              <button
                onClick={() => setShowAddAccountModal(false)}
                className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-slate-500" />
              </button>
            </div>

            <div className="space-y-4">
              <p className="text-slate-600">
                Link a new bill account so Haven can pay it automatically on your behalf.
              </p>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Bill Provider</label>
                <select className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent">
                  <option value="">Select a provider...</option>
                  <option value="electric">Electric Company</option>
                  <option value="gas">Gas Company</option>
                  <option value="water">Water Authority</option>
                  <option value="internet">Internet Provider</option>
                  <option value="trash">Trash/Recycling</option>
                  <option value="hoa">HOA Dues</option>
                  <option value="other">Other</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Account Number</label>
                <input
                  type="text"
                  placeholder="Enter your account number"
                  className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                />
              </div>

              <div className="p-3 bg-emerald-50 rounded-lg border border-emerald-200">
                <p className="text-sm text-emerald-800">
                  <strong>Secure:</strong> Your account info is encrypted and only used to pay your bills.
                </p>
              </div>

              <button
                onClick={() => {
                  setShowAddAccountModal(false);
                  showToast('Bill account added! Your manager will verify the connection.', 'success');
                }}
                className="w-full py-3 bg-emerald-600 text-white rounded-xl font-semibold hover:bg-emerald-700 transition-colors"
              >
                Add Account
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Animations */}
      <style jsx>{`
        @keyframes confetti {
          0% {
            transform: translateY(0) rotate(0deg);
            opacity: 1;
          }
          100% {
            transform: translateY(100vh) rotate(720deg);
            opacity: 0;
          }
        }
        .animate-confetti {
          animation: confetti 3s ease-out forwards;
        }
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
