'use client';

import { useState, useMemo } from 'react';
import {
  CreditCard as CreditCardIcon,
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
  Receipt,
  Download,
  Search,
  MoreHorizontal,
  X,
  Check,
  AlertCircle,
  ArrowDownRight,
  Banknote,
  Building2,
  FileText,
  Eye,
  RefreshCw,
} from 'lucide-react';
import { CreditCard } from '@/components/credit-card';

// ============================================================================
// TYPES
// ============================================================================

type TransactionStatus = 'completed' | 'pending' | 'failed' | 'requires_approval';
type TransactionCategory = 'utilities' | 'maintenance' | 'services' | 'projects' | 'insurance' | 'other';

interface Transaction {
  id: string;
  vendor: string;
  vendorLogo?: string;
  description: string;
  amount: number;
  category: TransactionCategory;
  status: TransactionStatus;
  date: Date;
  receiptUrl?: string;
  reference?: string;
  urgency?: 'low' | 'medium' | 'high';
  managerNote?: string;
  autoApproved?: boolean;
}

interface SpendingCategory {
  category: TransactionCategory;
  label: string;
  amount: number;
  icon: typeof Zap;
  color: string;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const MONTHLY_LIMIT = 5000;

const generateMockTransactions = (): Transaction[] => {
  const now = new Date();
  const thisMonth = now.getMonth();
  const thisYear = now.getFullYear();

  return [
    // Requires Approval - High amount
    {
      id: 'tx-1',
      vendor: 'Emergency Plumbing Co.',
      description: 'Emergency pipe burst repair - Kitchen',
      amount: 450,
      category: 'maintenance',
      status: 'requires_approval',
      date: new Date(thisYear, thisMonth, now.getDate(), 14, 30),
      urgency: 'high',
      managerNote: 'Urgent - Water damage prevention. Vendor is on-site waiting for approval.',
    },
    {
      id: 'tx-2',
      vendor: 'Ace Roofing Co.',
      description: 'Roof inspection and shingle replacement',
      amount: 875,
      category: 'maintenance',
      status: 'requires_approval',
      date: new Date(thisYear, thisMonth, now.getDate() - 1, 10, 0),
      urgency: 'medium',
      managerNote: 'Recommended after last storm. 3 quotes obtained - this is the best value.',
    },
    {
      id: 'tx-3',
      vendor: 'Smart Home Solutions',
      description: 'Nest thermostat installation',
      amount: 325,
      category: 'projects',
      status: 'requires_approval',
      date: new Date(thisYear, thisMonth, now.getDate() - 2, 16, 45),
      urgency: 'low',
      managerNote: 'Energy savings project. Expected ROI within 18 months.',
    },
    // Auto-approved (recurring/low amount)
    {
      id: 'tx-4',
      vendor: 'Power & Light Co.',
      description: 'Electric bill - December',
      amount: 187.43,
      category: 'utilities',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 3),
      autoApproved: true,
      receiptUrl: '/receipts/power-dec.pdf',
      reference: 'PWR-2024-1201',
    },
    {
      id: 'tx-5',
      vendor: 'City Water Authority',
      description: 'Water & sewer - December',
      amount: 94.50,
      category: 'utilities',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 5),
      autoApproved: true,
      reference: 'WTR-2024-DEC',
    },
    {
      id: 'tx-6',
      vendor: 'Green Thumb Landscaping',
      description: 'Monthly lawn maintenance',
      amount: 175,
      category: 'services',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 7),
      autoApproved: true,
      reference: 'GTL-2024-12',
    },
    {
      id: 'tx-7',
      vendor: 'SafeHome Insurance',
      description: 'Monthly premium - Homeowners',
      amount: 312,
      category: 'insurance',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 10),
      autoApproved: true,
      reference: 'INS-2024-DEC',
    },
    {
      id: 'tx-8',
      vendor: 'CleanPro Services',
      description: 'Bi-weekly house cleaning',
      amount: 180,
      category: 'services',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 12),
      autoApproved: true,
    },
    {
      id: 'tx-9',
      vendor: 'HandyPro Services',
      description: 'Garbage disposal replacement',
      amount: 195,
      category: 'maintenance',
      status: 'completed',
      date: new Date(thisYear, thisMonth, now.getDate() - 14),
      receiptUrl: '/receipts/handypro.pdf',
      reference: 'HP-87234',
    },
    // Pending transaction
    {
      id: 'tx-10',
      vendor: 'Pool Masters',
      description: 'Weekly pool service',
      amount: 85,
      category: 'services',
      status: 'pending',
      date: new Date(thisYear, thisMonth, now.getDate() - 1),
    },
    // Failed transaction
    {
      id: 'tx-11',
      vendor: 'Gas Company',
      description: 'Natural gas - December',
      amount: 78.50,
      category: 'utilities',
      status: 'failed',
      date: new Date(thisYear, thisMonth, now.getDate() - 4),
    },
  ];
};

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
  const now = new Date();
  const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays} days ago`;

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};

const getCategoryIcon = (category: TransactionCategory) => {
  switch (category) {
    case 'utilities':
      return Zap;
    case 'maintenance':
      return Wrench;
    case 'services':
      return Sparkles;
    case 'projects':
      return Home;
    case 'insurance':
      return ShieldCheck;
    default:
      return CreditCardIcon;
  }
};

const getCategoryColor = (category: TransactionCategory) => {
  switch (category) {
    case 'utilities':
      return { bg: 'bg-amber-100', text: 'text-amber-700', icon: 'text-amber-600' };
    case 'maintenance':
      return { bg: 'bg-blue-100', text: 'text-blue-700', icon: 'text-blue-600' };
    case 'services':
      return { bg: 'bg-purple-100', text: 'text-purple-700', icon: 'text-purple-600' };
    case 'projects':
      return { bg: 'bg-rose-100', text: 'text-rose-700', icon: 'text-rose-600' };
    case 'insurance':
      return { bg: 'bg-emerald-100', text: 'text-emerald-700', icon: 'text-emerald-600' };
    default:
      return { bg: 'bg-slate-100', text: 'text-slate-700', icon: 'text-slate-600' };
  }
};

const getStatusBadge = (status: TransactionStatus) => {
  switch (status) {
    case 'completed':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
          <CheckCircle2 className="w-3 h-3" />
          Paid
        </span>
      );
    case 'pending':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
          <Clock className="w-3 h-3" />
          Processing
        </span>
      );
    case 'failed':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700">
          <XCircle className="w-3 h-3" />
          Failed
        </span>
      );
    case 'requires_approval':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-700">
          <AlertTriangle className="w-3 h-3" />
          Needs Approval
        </span>
      );
    default:
      return null;
  }
};

// ============================================================================
// COMPONENTS
// ============================================================================

function SpendPowerGauge({ spent, limit }: { spent: number; limit: number }) {
  const remaining = Math.max(0, limit - spent);
  const percentUsed = Math.min(100, (spent / limit) * 100);

  // Color based on utilization
  const getColor = () => {
    if (percentUsed >= 90) return { stroke: 'stroke-red-500', text: 'text-red-600', bg: 'bg-red-500' };
    if (percentUsed >= 75) return { stroke: 'stroke-amber-500', text: 'text-amber-600', bg: 'bg-amber-500' };
    return { stroke: 'stroke-emerald-500', text: 'text-emerald-600', bg: 'bg-emerald-500' };
  };

  const color = getColor();
  const circumference = 2 * Math.PI * 54;
  const strokeDashoffset = circumference - (percentUsed / 100) * circumference;

  return (
    <div className="flex items-center gap-8">
      {/* Circular Gauge */}
      <div className="relative w-36 h-36">
        <svg className="w-full h-full -rotate-90" viewBox="0 0 120 120">
          {/* Background circle */}
          <circle
            cx="60"
            cy="60"
            r="54"
            fill="none"
            stroke="currentColor"
            strokeWidth="8"
            className="text-slate-200"
          />
          {/* Progress circle */}
          <circle
            cx="60"
            cy="60"
            r="54"
            fill="none"
            strokeWidth="8"
            strokeLinecap="round"
            className={color.stroke}
            style={{
              strokeDasharray: circumference,
              strokeDashoffset,
              transition: 'stroke-dashoffset 0.5s ease-in-out',
            }}
          />
        </svg>
        {/* Center content */}
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className={`text-2xl font-bold ${color.text}`}>{Math.round(percentUsed)}%</span>
          <span className="text-xs text-slate-500">Used</span>
        </div>
      </div>

      {/* Stats */}
      <div className="space-y-4">
        <div>
          <div className="text-sm text-slate-500 mb-1">Monthly Limit</div>
          <div className="text-2xl font-bold text-slate-900">{formatCurrency(limit)}</div>
        </div>
        <div className="flex gap-6">
          <div>
            <div className="text-sm text-slate-500 mb-0.5">Spent</div>
            <div className="text-lg font-semibold text-slate-700">{formatCurrency(spent)}</div>
          </div>
          <div>
            <div className="text-sm text-slate-500 mb-0.5">Remaining</div>
            <div className={`text-lg font-semibold ${color.text}`}>{formatCurrency(remaining)}</div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ApprovalCard({
  transaction,
  onApprove,
  onDecline,
}: {
  transaction: Transaction;
  onApprove: (id: string) => void;
  onDecline: (id: string) => void;
}) {
  const CategoryIcon = getCategoryIcon(transaction.category);
  const categoryColor = getCategoryColor(transaction.category);

  const getUrgencyBadge = () => {
    if (!transaction.urgency) return null;
    switch (transaction.urgency) {
      case 'high':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700 border border-red-200">
            <AlertCircle className="w-3 h-3" />
            Urgent
          </span>
        );
      case 'medium':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
            Normal
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-600">
            Low Priority
          </span>
        );
    }
  };

  return (
    <div
      className={`bg-white rounded-xl border-2 p-5 transition-all hover:shadow-lg ${
        transaction.urgency === 'high' ? 'border-red-200 bg-red-50/30' : 'border-slate-200'
      }`}
    >
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-start gap-3">
          <div className={`p-2.5 rounded-xl ${categoryColor.bg}`}>
            <CategoryIcon className={`w-5 h-5 ${categoryColor.icon}`} />
          </div>
          <div>
            <div className="font-semibold text-slate-900">{transaction.vendor}</div>
            <div className="text-sm text-slate-500">{transaction.description}</div>
            <div className="flex items-center gap-2 mt-2">
              {getUrgencyBadge()}
              <span className="text-xs text-slate-400">{formatDate(transaction.date)}</span>
            </div>
          </div>
        </div>
        <div className="text-right">
          <div className="text-xl font-bold text-slate-900">{formatCurrency(transaction.amount)}</div>
          <div className={`text-xs font-medium ${categoryColor.text}`}>
            {transaction.category.charAt(0).toUpperCase() + transaction.category.slice(1)}
          </div>
        </div>
      </div>

      {transaction.managerNote && (
        <div className="mb-4 p-3 bg-slate-50 rounded-lg border border-slate-200">
          <div className="flex items-start gap-2">
            <FileText className="w-4 h-4 text-slate-400 mt-0.5 flex-shrink-0" />
            <div>
              <div className="text-xs font-medium text-slate-500 mb-0.5">Manager Note</div>
              <div className="text-sm text-slate-700">{transaction.managerNote}</div>
            </div>
          </div>
        </div>
      )}

      <div className="flex gap-3">
        <button
          onClick={() => onApprove(transaction.id)}
          className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-emerald-600 text-white rounded-lg font-medium hover:bg-emerald-700 transition-colors"
        >
          <Check className="w-4 h-4" />
          Approve
        </button>
        <button
          onClick={() => onDecline(transaction.id)}
          className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 border border-slate-300 text-slate-700 rounded-lg font-medium hover:bg-slate-50 transition-colors"
        >
          <X className="w-4 h-4" />
          Decline
        </button>
      </div>
    </div>
  );
}

function TransactionRow({ transaction }: { transaction: Transaction }) {
  const CategoryIcon = getCategoryIcon(transaction.category);
  const categoryColor = getCategoryColor(transaction.category);

  return (
    <div className="flex items-center gap-4 py-4 border-b border-slate-100 last:border-0 hover:bg-slate-50/50 transition-colors -mx-4 px-4">
      <div className={`p-2.5 rounded-xl ${categoryColor.bg} flex-shrink-0`}>
        <CategoryIcon className={`w-5 h-5 ${categoryColor.icon}`} />
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-slate-900 truncate">{transaction.vendor}</span>
          {transaction.autoApproved && (
            <span className="px-1.5 py-0.5 text-[10px] font-medium bg-slate-100 text-slate-500 rounded">
              Auto
            </span>
          )}
        </div>
        <div className="text-sm text-slate-500 truncate">{transaction.description}</div>
      </div>

      <div className="flex-shrink-0 text-right">
        <div className="font-semibold text-slate-900">{formatCurrency(transaction.amount)}</div>
        <div className="text-xs text-slate-400">{formatDate(transaction.date)}</div>
      </div>

      <div className="flex-shrink-0">{getStatusBadge(transaction.status)}</div>

      <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-400">
        <MoreHorizontal className="w-4 h-4" />
      </button>
    </div>
  );
}

function SpendingBreakdown({ categories }: { categories: SpendingCategory[] }) {
  const total = categories.reduce((sum, cat) => sum + cat.amount, 0);

  return (
    <div className="space-y-3">
      {categories.map((cat) => {
        const Icon = cat.icon;
        const percent = total > 0 ? (cat.amount / total) * 100 : 0;
        const color = getCategoryColor(cat.category);

        return (
          <div key={cat.category} className="flex items-center gap-3">
            <div className={`p-2 rounded-lg ${color.bg}`}>
              <Icon className={`w-4 h-4 ${color.icon}`} />
            </div>
            <div className="flex-1">
              <div className="flex items-center justify-between mb-1">
                <span className="text-sm font-medium text-slate-700">{cat.label}</span>
                <span className="text-sm font-semibold text-slate-900">{formatCurrency(cat.amount)}</span>
              </div>
              <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                <div
                  className={`h-full ${color.bg.replace('100', '500')} rounded-full transition-all duration-500`}
                  style={{ width: `${percent}%` }}
                />
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

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

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function BillingPage() {
  const [transactions, setTransactions] = useState<Transaction[]>(generateMockTransactions);
  const [isCardLocked, setIsCardLocked] = useState(false);
  const [showConfetti, setShowConfetti] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);
  const [filterCategory, setFilterCategory] = useState<TransactionCategory | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Show toast helper
  const showToast = (message: string, type: 'success' | 'error' | 'info' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  // Handle card lock toggle
  const handleCardLock = (locked: boolean) => {
    setIsCardLocked(locked);
    showToast(
      locked ? 'Card frozen. No new charges allowed.' : 'Card activated. Ready for charges.',
      locked ? 'info' : 'success'
    );
  };

  // Handle approval
  const handleApprove = (id: string) => {
    setTransactions((prev) =>
      prev.map((tx) => (tx.id === id ? { ...tx, status: 'completed' as TransactionStatus } : tx))
    );
    setShowConfetti(true);
    setTimeout(() => setShowConfetti(false), 2500);
    showToast('Payment approved successfully!', 'success');
  };

  // Handle decline
  const handleDecline = (id: string) => {
    setTransactions((prev) => prev.filter((tx) => tx.id !== id));
    showToast('Payment declined.', 'info');
  };

  // Computed values
  const pendingApprovals = useMemo(
    () => transactions.filter((tx) => tx.status === 'requires_approval'),
    [transactions]
  );

  const recentActivity = useMemo(() => {
    let filtered = transactions.filter((tx) => tx.status !== 'requires_approval');

    if (filterCategory !== 'all') {
      filtered = filtered.filter((tx) => tx.category === filterCategory);
    }

    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (tx) =>
          tx.vendor.toLowerCase().includes(query) || tx.description.toLowerCase().includes(query)
      );
    }

    return filtered.sort((a, b) => b.date.getTime() - a.date.getTime());
  }, [transactions, filterCategory, searchQuery]);

  const monthlySpent = useMemo(() => {
    const now = new Date();
    return transactions
      .filter(
        (tx) =>
          tx.status === 'completed' &&
          tx.date.getMonth() === now.getMonth() &&
          tx.date.getFullYear() === now.getFullYear()
      )
      .reduce((sum, tx) => sum + tx.amount, 0);
  }, [transactions]);

  const spendingByCategory = useMemo((): SpendingCategory[] => {
    const categoryTotals: Record<TransactionCategory, number> = {
      utilities: 0,
      maintenance: 0,
      services: 0,
      projects: 0,
      insurance: 0,
      other: 0,
    };

    transactions
      .filter((tx) => tx.status === 'completed')
      .forEach((tx) => {
        categoryTotals[tx.category] += tx.amount;
      });

    const categories: SpendingCategory[] = [
      { category: 'utilities', label: 'Utilities', amount: categoryTotals.utilities, icon: Zap, color: 'amber' },
      { category: 'maintenance', label: 'Maintenance', amount: categoryTotals.maintenance, icon: Wrench, color: 'blue' },
      { category: 'services', label: 'Services', amount: categoryTotals.services, icon: Sparkles, color: 'purple' },
      { category: 'insurance', label: 'Insurance', amount: categoryTotals.insurance, icon: ShieldCheck, color: 'emerald' },
      { category: 'projects', label: 'Projects', amount: categoryTotals.projects, icon: Home, color: 'rose' },
    ];
    return categories.filter((cat) => cat.amount > 0);
  }, [transactions]);

  // Next payment date (1st of next month)
  const nextPaymentDate = useMemo(() => {
    const now = new Date();
    const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    return nextMonth.toLocaleDateString('en-US', { month: 'long', day: 'numeric' });
  }, []);

  const statementTotal = useMemo(() => {
    return transactions
      .filter((tx) => tx.status === 'completed' || tx.status === 'pending')
      .reduce((sum, tx) => sum + tx.amount, 0);
  }, [transactions]);

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

      {/* Header */}
      <div className="bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Money</h1>
              <p className="text-slate-500 mt-1">Manage your Haven Estate Card and payments</p>
            </div>

            <div className="flex items-center gap-3">
              <button className="flex items-center gap-2 px-4 py-2 border border-slate-300 rounded-lg text-slate-700 hover:bg-slate-50 transition-colors">
                <Download className="w-4 h-4" />
                <span className="hidden sm:inline">Export</span>
              </button>
              <button className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors">
                <Receipt className="w-4 h-4" />
                View Statement
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Main Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column - Card & Stats */}
          <div className="lg:col-span-2 space-y-6">
            {/* Spend Power & Card */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <div className="p-6 border-b border-slate-100">
                <h2 className="text-lg font-semibold text-slate-900 mb-6">Spend Power</h2>
                <SpendPowerGauge spent={monthlySpent} limit={MONTHLY_LIMIT} />
              </div>

              <div className="p-6 bg-slate-50/50">
                <div className="flex flex-col lg:flex-row items-center gap-6">
                  <div className="w-full lg:w-auto">
                    <CreditCard
                      cardholderName="HAVEN ESTATE"
                      lastFour="4242"
                      expiry="12/28"
                      isLocked={isCardLocked}
                      onToggleLock={handleCardLock}
                    />
                  </div>

                  <div className="flex-1 w-full lg:w-auto space-y-4">
                    {/* Statement Balance */}
                    <div className="bg-white rounded-xl border border-slate-200 p-4">
                      <div className="flex items-center justify-between mb-3">
                        <span className="text-sm text-slate-500">Current Statement</span>
                        <span className="text-xs text-slate-400">Due {nextPaymentDate}</span>
                      </div>
                      <div className="text-3xl font-bold text-slate-900 mb-4">
                        {formatCurrency(statementTotal)}
                      </div>
                      <button className="w-full flex items-center justify-center gap-2 px-4 py-2.5 bg-slate-900 text-white rounded-lg font-medium hover:bg-slate-800 transition-colors">
                        <Banknote className="w-4 h-4" />
                        Pay Statement
                      </button>
                      <div className="mt-3 flex items-center justify-center gap-2 text-xs text-slate-500">
                        <RefreshCw className="w-3 h-3" />
                        Auto-pay enabled for {nextPaymentDate}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Pending Approvals */}
            {pendingApprovals.length > 0 && (
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <h2 className="text-lg font-semibold text-slate-900">Needs Your Approval</h2>
                    <span className="px-2 py-0.5 bg-orange-100 text-orange-700 text-xs font-semibold rounded-full">
                      {pendingApprovals.length}
                    </span>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {pendingApprovals.map((tx) => (
                    <ApprovalCard
                      key={tx.id}
                      transaction={tx}
                      onApprove={handleApprove}
                      onDecline={handleDecline}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* Recent Activity */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm">
              <div className="p-6 border-b border-slate-100">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  <h2 className="text-lg font-semibold text-slate-900">Recent Activity</h2>

                  <div className="flex items-center gap-3">
                    {/* Search */}
                    <div className="relative">
                      <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                      <input
                        type="text"
                        placeholder="Search..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="pl-9 pr-4 py-2 w-40 text-sm border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                      />
                    </div>

                    {/* Filter */}
                    <select
                      value={filterCategory}
                      onChange={(e) => setFilterCategory(e.target.value as TransactionCategory | 'all')}
                      className="px-3 py-2 text-sm border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                    >
                      <option value="all">All Categories</option>
                      <option value="utilities">Utilities</option>
                      <option value="maintenance">Maintenance</option>
                      <option value="services">Services</option>
                      <option value="projects">Projects</option>
                      <option value="insurance">Insurance</option>
                    </select>
                  </div>
                </div>
              </div>

              <div className="p-4">
                {recentActivity.length === 0 ? (
                  <div className="py-12 text-center text-slate-500">
                    <CreditCardIcon className="w-12 h-12 mx-auto mb-3 text-slate-300" />
                    <p>No transactions found</p>
                  </div>
                ) : (
                  recentActivity.map((tx) => <TransactionRow key={tx.id} transaction={tx} />)
                )}
              </div>

              {recentActivity.length > 0 && (
                <div className="p-4 border-t border-slate-100">
                  <button className="w-full flex items-center justify-center gap-2 px-4 py-2 text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors font-medium">
                    View All Transactions
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Right Column - Sidebar */}
          <div className="space-y-6">
            {/* Quick Stats */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
              <h3 className="font-semibold text-slate-900 mb-4">This Month</h3>

              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-emerald-100 rounded-lg">
                      <ArrowDownRight className="w-4 h-4 text-emerald-600" />
                    </div>
                    <span className="text-sm text-slate-600">Total Spent</span>
                  </div>
                  <span className="font-semibold text-slate-900">{formatCurrency(monthlySpent)}</span>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-amber-100 rounded-lg">
                      <Clock className="w-4 h-4 text-amber-600" />
                    </div>
                    <span className="text-sm text-slate-600">Pending</span>
                  </div>
                  <span className="font-semibold text-slate-900">
                    {formatCurrency(
                      transactions.filter((tx) => tx.status === 'pending').reduce((sum, tx) => sum + tx.amount, 0)
                    )}
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-orange-100 rounded-lg">
                      <AlertTriangle className="w-4 h-4 text-orange-600" />
                    </div>
                    <span className="text-sm text-slate-600">Awaiting Approval</span>
                  </div>
                  <span className="font-semibold text-slate-900">
                    {formatCurrency(pendingApprovals.reduce((sum, tx) => sum + tx.amount, 0))}
                  </span>
                </div>
              </div>
            </div>

            {/* Spending Breakdown */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
              <h3 className="font-semibold text-slate-900 mb-4">Spending Breakdown</h3>
              <SpendingBreakdown categories={spendingByCategory} />
            </div>

            {/* Billing Info */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
              <h3 className="font-semibold text-slate-900 mb-4">Billing Account</h3>

              <div className="space-y-4">
                <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
                  <Building2 className="w-5 h-5 text-slate-400" />
                  <div className="flex-1">
                    <div className="text-sm font-medium text-slate-700">Chase Checking</div>
                    <div className="text-xs text-slate-500">•••• 9876</div>
                  </div>
                  <span className="px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded">
                    Default
                  </span>
                </div>

                <div className="flex items-center justify-between text-sm">
                  <span className="text-slate-500">Auto-pay</span>
                  <span className="text-emerald-600 font-medium">Enabled</span>
                </div>

                <div className="flex items-center justify-between text-sm">
                  <span className="text-slate-500">Next payment</span>
                  <span className="text-slate-700 font-medium">{nextPaymentDate}</span>
                </div>

                <button className="w-full px-4 py-2 border border-slate-300 rounded-lg text-slate-700 text-sm font-medium hover:bg-slate-50 transition-colors">
                  Manage Payment Methods
                </button>
              </div>
            </div>

            {/* Help Card */}
            <div className="bg-gradient-to-br from-emerald-600 to-emerald-700 rounded-2xl p-6 text-white">
              <div className="flex items-start gap-3 mb-4">
                <div className="p-2 bg-white/20 rounded-lg">
                  <Eye className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-semibold mb-1">Haven Monitors Everything</h3>
                  <p className="text-sm text-emerald-100">
                    Your manager reviews all charges over $200 before they post.
                  </p>
                </div>
              </div>
              <button className="w-full px-4 py-2 bg-white text-emerald-700 rounded-lg text-sm font-medium hover:bg-emerald-50 transition-colors">
                Learn About Protections
              </button>
            </div>
          </div>
        </div>
      </div>

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
