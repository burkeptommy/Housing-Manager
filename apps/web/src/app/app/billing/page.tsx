'use client';

import { useState, useMemo } from 'react';
import {
  Wallet,
  Plus,
  CreditCard,
  RefreshCw,
  Settings,
  CheckCircle2,
  XCircle,
  Clock,
  AlertTriangle,
  Receipt,
  Eye,
  Download,
  Search,
  ChevronRight,
  Shield,
  Lock,
  ArrowUpRight,
  ArrowDownRight,
  Users,
  Zap,
  ShieldCheck,
  Home,
  Wrench,
  FileText,
  MoreVertical,
  X,
  Check,
  AlertCircle,
  Building,
  Sparkles,
} from 'lucide-react';

// Types
type TransactionStatus = 'completed' | 'pending' | 'failed' | 'disputed';
type TransactionCategory = 'utilities' | 'maintenance' | 'services' | 'projects' | 'insurance' | 'other';

interface PaymentMethod {
  id: string;
  type: 'card' | 'bank';
  last4: string;
  brand?: string;
  bankName?: string;
  isDefault: boolean;
  expiresAt?: string;
}

interface PendingApproval {
  id: string;
  vendor: string;
  vendorLogo?: string;
  description: string;
  amount: number;
  category: TransactionCategory;
  requestedAt: Date;
  dueDate?: Date;
  managerNote?: string;
  urgency: 'low' | 'medium' | 'high';
}

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
  paymentMethod?: string;
  reference?: string;
}

interface SpendingCategory {
  category: TransactionCategory;
  label: string;
  amount: number;
  budget: number;
  icon: typeof Zap;
  color: string;
}

interface FamilyMember {
  id: string;
  name: string;
  avatar?: string;
  initials: string;
  owedAmount: number;
  paidAmount: number;
}

// Mock Data
const mockPaymentMethods: PaymentMethod[] = [
  { id: '1', type: 'card', last4: '4242', brand: 'Visa', isDefault: true, expiresAt: '12/26' },
  { id: '2', type: 'bank', last4: '9876', bankName: 'Chase', isDefault: false },
];

const mockPendingApprovals: PendingApproval[] = [
  {
    id: '1',
    vendor: 'Ace Roofing Co.',
    description: 'Roof inspection and minor repairs',
    amount: 850,
    category: 'maintenance',
    requestedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
    managerNote: 'Recommended - found loose shingles during last inspection',
    urgency: 'high',
  },
  {
    id: '2',
    vendor: 'Green Thumb Landscaping',
    description: 'Monthly lawn care - December',
    amount: 175,
    category: 'services',
    requestedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    urgency: 'low',
  },
  {
    id: '3',
    vendor: 'City Water Services',
    description: 'Q4 Water/Sewer bill',
    amount: 245.50,
    category: 'utilities',
    requestedAt: new Date(Date.now() - 4 * 60 * 60 * 1000),
    dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    urgency: 'medium',
  },
];

const mockTransactions: Transaction[] = [
  {
    id: '1',
    vendor: 'Power & Light Co.',
    description: 'Electric bill - November',
    amount: 187.43,
    category: 'utilities',
    status: 'completed',
    date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    receiptUrl: '/receipts/power-nov.pdf',
    paymentMethod: 'Visa •••• 4242',
    reference: 'PWR-2024-1128',
  },
  {
    id: '2',
    vendor: 'SafeHome Insurance',
    description: 'Monthly premium',
    amount: 312.00,
    category: 'insurance',
    status: 'completed',
    date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    receiptUrl: '/receipts/insurance-dec.pdf',
    paymentMethod: 'Bank •••• 9876',
    reference: 'INS-2024-DEC',
  },
  {
    id: '3',
    vendor: 'HandyPro Services',
    description: 'Garbage disposal replacement',
    amount: 425.00,
    category: 'maintenance',
    status: 'completed',
    date: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000),
    receiptUrl: '/receipts/handypro-disposal.pdf',
    paymentMethod: 'Visa •••• 4242',
    reference: 'HP-87234',
  },
  {
    id: '4',
    vendor: 'Xfinity Internet',
    description: 'Monthly internet service',
    amount: 89.99,
    category: 'utilities',
    status: 'completed',
    date: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000),
    paymentMethod: 'Visa •••• 4242',
  },
  {
    id: '5',
    vendor: 'Clean Sweep Pest Control',
    description: 'Quarterly pest treatment',
    amount: 149.00,
    category: 'services',
    status: 'pending',
    date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
  },
  {
    id: '6',
    vendor: 'Premium HVAC',
    description: 'Furnace tune-up',
    amount: 189.00,
    category: 'maintenance',
    status: 'failed',
    date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    paymentMethod: 'Visa •••• 4242',
  },
  {
    id: '7',
    vendor: 'City Gas Company',
    description: 'Natural gas - November',
    amount: 78.22,
    category: 'utilities',
    status: 'completed',
    date: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000),
    receiptUrl: '/receipts/gas-nov.pdf',
    paymentMethod: 'Bank •••• 9876',
  },
  {
    id: '8',
    vendor: 'Tile Pro Installations',
    description: 'Kitchen backsplash deposit',
    amount: 800.00,
    category: 'projects',
    status: 'disputed',
    date: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000),
    paymentMethod: 'Visa •••• 4242',
    reference: 'TP-2024-4521',
  },
];

const mockSpendingCategories: SpendingCategory[] = [
  { category: 'utilities', label: 'Utilities', amount: 355.64, budget: 400, icon: Zap, color: 'amber' },
  { category: 'maintenance', label: 'Maintenance', amount: 614.00, budget: 500, icon: Wrench, color: 'blue' },
  { category: 'services', label: 'Services', amount: 324.00, budget: 400, icon: Sparkles, color: 'purple' },
  { category: 'insurance', label: 'Insurance', amount: 312.00, budget: 350, icon: ShieldCheck, color: 'green' },
  { category: 'projects', label: 'Projects', amount: 800.00, budget: 1000, icon: Home, color: 'rose' },
];

const mockFamilyMembers: FamilyMember[] = [
  { id: '1', name: 'Bob Homeowner', initials: 'BH', owedAmount: 0, paidAmount: 1856.42 },
  { id: '2', name: 'Alice Homeowner', initials: 'AH', owedAmount: 425.00, paidAmount: 312.00 },
];

// Category config
const categoryConfig: Record<TransactionCategory, { icon: typeof Zap; color: string; label: string }> = {
  utilities: { icon: Zap, color: 'amber', label: 'Utilities' },
  maintenance: { icon: Wrench, color: 'blue', label: 'Maintenance' },
  services: { icon: Sparkles, color: 'purple', label: 'Services' },
  projects: { icon: Home, color: 'rose', label: 'Projects' },
  insurance: { icon: ShieldCheck, color: 'green', label: 'Insurance' },
  other: { icon: FileText, color: 'slate', label: 'Other' },
};

export default function MoneyPage() {
  // State
  const [walletBalance] = useState(2847.50);
  const [monthlyBudget] = useState(3500);
  const [autoRefillEnabled, setAutoRefillEnabled] = useState(true);
  const [autoRefillThreshold] = useState(500);
  const [paymentMethods] = useState<PaymentMethod[]>(mockPaymentMethods);
  const [pendingApprovals, setPendingApprovals] = useState<PendingApproval[]>(mockPendingApprovals);
  const [transactions] = useState<Transaction[]>(mockTransactions);
  const [spendingCategories] = useState<SpendingCategory[]>(mockSpendingCategories);
  const [familyMembers] = useState<FamilyMember[]>(mockFamilyMembers);

  // UI State
  const [showAddFundsModal, setShowAddFundsModal] = useState(false);
  const [showManageCardsModal, setShowManageCardsModal] = useState(false);
  const [showReceiptModal, setShowReceiptModal] = useState<Transaction | null>(null);
  const [showApprovalDetail, setShowApprovalDetail] = useState<PendingApproval | null>(null);
  const [transactionFilter, setTransactionFilter] = useState<TransactionCategory | 'all'>('all');
  const [transactionSearch, setTransactionSearch] = useState('');
  const [expandedTransaction, setExpandedTransaction] = useState<string | null>(null);

  // Computed values
  const totalSpent = useMemo(() => {
    return spendingCategories.reduce((sum, cat) => sum + cat.amount, 0);
  }, [spendingCategories]);

  const budgetPercentage = useMemo(() => {
    return Math.min((totalSpent / monthlyBudget) * 100, 100);
  }, [totalSpent, monthlyBudget]);

  const filteredTransactions = useMemo(() => {
    let filtered = transactions;
    if (transactionFilter !== 'all') {
      filtered = filtered.filter(t => t.category === transactionFilter);
    }
    if (transactionSearch) {
      const search = transactionSearch.toLowerCase();
      filtered = filtered.filter(t =>
        t.vendor.toLowerCase().includes(search) ||
        t.description.toLowerCase().includes(search)
      );
    }
    return filtered;
  }, [transactions, transactionFilter, transactionSearch]);

  const monthlyChange = useMemo(() => {
    const lastMonthTotal = 2156.78; // Mock previous month
    const change = ((totalSpent - lastMonthTotal) / lastMonthTotal) * 100;
    return change;
  }, [totalSpent]);

  // Handlers
  const handleApprove = (approval: PendingApproval) => {
    setPendingApprovals(prev => prev.filter(a => a.id !== approval.id));
    // In real app, would call API
  };

  const handleReject = (approval: PendingApproval) => {
    setPendingApprovals(prev => prev.filter(a => a.id !== approval.id));
    // In real app, would call API
  };

  // Format helpers
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
    });
  };

  const formatDateFull = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const getStatusBadge = (status: TransactionStatus) => {
    const styles: Record<TransactionStatus, { bg: string; text: string; icon: typeof CheckCircle2 }> = {
      completed: { bg: 'bg-green-100', text: 'text-green-700', icon: CheckCircle2 },
      pending: { bg: 'bg-yellow-100', text: 'text-yellow-700', icon: Clock },
      failed: { bg: 'bg-red-100', text: 'text-red-700', icon: XCircle },
      disputed: { bg: 'bg-orange-100', text: 'text-orange-700', icon: AlertTriangle },
    };
    return styles[status];
  };

  const getUrgencyBadge = (urgency: 'low' | 'medium' | 'high') => {
    const styles = {
      low: 'bg-slate-100 text-slate-600',
      medium: 'bg-yellow-100 text-yellow-700',
      high: 'bg-red-100 text-red-700',
    };
    return styles[urgency];
  };

  return (
    <div className="space-y-6 pb-20">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Financial Command Center</h1>
          <p className="text-slate-600 mt-1">Manage your house finances with confidence</p>
        </div>
        <div className="flex items-center gap-2 text-sm text-slate-500">
          <Shield className="w-4 h-4 text-emerald-600" />
          <span>256-bit encrypted</span>
        </div>
      </div>

      {/* House Wallet - Hero Section */}
      <div className="bg-gradient-to-br from-emerald-600 to-emerald-700 rounded-2xl p-6 text-white shadow-lg">
        <div className="flex items-start justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center backdrop-blur-sm">
              <Wallet className="w-6 h-6" />
            </div>
            <div>
              <p className="text-emerald-100 text-sm font-medium">House Wallet</p>
              <p className="text-3xl font-bold">{formatCurrency(walletBalance)}</p>
            </div>
          </div>
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <Settings className="w-5 h-5" />
          </button>
        </div>

        {/* Wallet Quick Actions */}
        <div className="grid grid-cols-4 gap-3 mb-6">
          <button
            onClick={() => setShowAddFundsModal(true)}
            className="flex flex-col items-center gap-1.5 p-3 bg-white/10 hover:bg-white/20 rounded-xl transition-colors"
          >
            <Plus className="w-5 h-5" />
            <span className="text-xs font-medium">Add Funds</span>
          </button>
          <button
            onClick={() => setAutoRefillEnabled(!autoRefillEnabled)}
            className={`flex flex-col items-center gap-1.5 p-3 rounded-xl transition-colors ${
              autoRefillEnabled ? 'bg-white/20' : 'bg-white/10 hover:bg-white/20'
            }`}
          >
            <RefreshCw className={`w-5 h-5 ${autoRefillEnabled ? 'text-emerald-200' : ''}`} />
            <span className="text-xs font-medium">Auto-Refill</span>
          </button>
          <button
            onClick={() => setShowManageCardsModal(true)}
            className="flex flex-col items-center gap-1.5 p-3 bg-white/10 hover:bg-white/20 rounded-xl transition-colors"
          >
            <CreditCard className="w-5 h-5" />
            <span className="text-xs font-medium">Cards</span>
          </button>
          <button className="flex flex-col items-center gap-1.5 p-3 bg-white/10 hover:bg-white/20 rounded-xl transition-colors">
            <FileText className="w-5 h-5" />
            <span className="text-xs font-medium">Statements</span>
          </button>
        </div>

        {/* Auto-Refill Status */}
        {autoRefillEnabled && (
          <div className="flex items-center gap-2 text-sm text-emerald-100 bg-white/10 rounded-lg px-3 py-2">
            <RefreshCw className="w-4 h-4" />
            <span>Auto-refill enabled when balance drops below {formatCurrency(autoRefillThreshold)}</span>
          </div>
        )}

        {/* Payment Methods Preview */}
        <div className="mt-4 flex items-center gap-3">
          {paymentMethods.slice(0, 2).map((method) => (
            <div key={method.id} className="flex items-center gap-2 bg-white/10 rounded-lg px-3 py-2 text-sm">
              {method.type === 'card' ? (
                <CreditCard className="w-4 h-4" />
              ) : (
                <Building className="w-4 h-4" />
              )}
              <span>
                {method.type === 'card' ? method.brand : method.bankName} •••• {method.last4}
              </span>
              {method.isDefault && (
                <span className="text-xs bg-white/20 px-1.5 py-0.5 rounded">Default</span>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Approvals Inbox */}
      {pendingApprovals.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm border border-slate-200">
          <div className="p-4 border-b border-slate-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 bg-amber-100 rounded-lg flex items-center justify-center">
                  <Clock className="w-4 h-4 text-amber-600" />
                </div>
                <div>
                  <h2 className="font-semibold text-slate-900">Approvals Inbox</h2>
                  <p className="text-sm text-slate-500">{pendingApprovals.length} payments awaiting your authorization</p>
                </div>
              </div>
              <button className="text-sm text-emerald-600 font-medium hover:text-emerald-700">
                Approve All
              </button>
            </div>
          </div>

          <div className="divide-y divide-slate-100">
            {pendingApprovals.map((approval) => {
              const CategoryIcon = categoryConfig[approval.category].icon;
              return (
                <div
                  key={approval.id}
                  className="p-4 hover:bg-slate-50 transition-colors cursor-pointer"
                  onClick={() => setShowApprovalDetail(approval)}
                >
                  <div className="flex items-start gap-4">
                    <div className={`w-10 h-10 rounded-lg flex items-center justify-center bg-${categoryConfig[approval.category].color}-100`}>
                      <CategoryIcon className={`w-5 h-5 text-${categoryConfig[approval.category].color}-600`} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-4">
                        <div>
                          <p className="font-medium text-slate-900">{approval.vendor}</p>
                          <p className="text-sm text-slate-500 truncate">{approval.description}</p>
                          {approval.managerNote && (
                            <p className="text-xs text-emerald-600 mt-1 flex items-center gap-1">
                              <Sparkles className="w-3 h-3" />
                              {approval.managerNote}
                            </p>
                          )}
                        </div>
                        <div className="text-right flex-shrink-0">
                          <p className="font-semibold text-slate-900">{formatCurrency(approval.amount)}</p>
                          <span className={`text-xs px-2 py-0.5 rounded-full ${getUrgencyBadge(approval.urgency)}`}>
                            {approval.urgency === 'high' ? 'Urgent' : approval.urgency === 'medium' ? 'Due Soon' : 'Normal'}
                          </span>
                        </div>
                      </div>
                      {approval.dueDate && (
                        <p className="text-xs text-slate-400 mt-1">Due {formatDate(approval.dueDate)}</p>
                      )}
                    </div>
                  </div>

                  {/* Quick Actions */}
                  <div className="flex items-center gap-2 mt-3 ml-14">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleApprove(approval);
                      }}
                      className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition-colors"
                    >
                      <Check className="w-4 h-4" />
                      Approve
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleReject(approval);
                      }}
                      className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-100 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-200 transition-colors"
                    >
                      <X className="w-4 h-4" />
                      Decline
                    </button>
                    <button className="p-1.5 text-slate-400 hover:text-slate-600 transition-colors">
                      <MoreVertical className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Budget & Spending Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Budget Gauge */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-slate-900">Monthly Budget</h2>
            <span className="text-sm text-slate-500">December 2024</span>
          </div>

          {/* Circular Gauge */}
          <div className="flex items-center justify-center mb-6">
            <div className="relative">
              <svg className="w-40 h-40 transform -rotate-90">
                <circle
                  cx="80"
                  cy="80"
                  r="70"
                  stroke="#e2e8f0"
                  strokeWidth="12"
                  fill="none"
                />
                <circle
                  cx="80"
                  cy="80"
                  r="70"
                  stroke={budgetPercentage > 90 ? '#ef4444' : budgetPercentage > 75 ? '#f59e0b' : '#10b981'}
                  strokeWidth="12"
                  fill="none"
                  strokeLinecap="round"
                  strokeDasharray={`${(budgetPercentage / 100) * 439.82} 439.82`}
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <p className="text-2xl font-bold text-slate-900">{formatCurrency(totalSpent)}</p>
                <p className="text-sm text-slate-500">of {formatCurrency(monthlyBudget)}</p>
              </div>
            </div>
          </div>

          {/* Monthly Comparison */}
          <div className="flex items-center justify-center gap-2 text-sm">
            {monthlyChange > 0 ? (
              <>
                <ArrowUpRight className="w-4 h-4 text-red-500" />
                <span className="text-red-600 font-medium">{monthlyChange.toFixed(1)}%</span>
                <span className="text-slate-500">vs last month</span>
              </>
            ) : (
              <>
                <ArrowDownRight className="w-4 h-4 text-green-500" />
                <span className="text-green-600 font-medium">{Math.abs(monthlyChange).toFixed(1)}%</span>
                <span className="text-slate-500">vs last month</span>
              </>
            )}
          </div>

          {/* Budget Remaining */}
          <div className="mt-4 p-3 bg-slate-50 rounded-lg">
            <div className="flex items-center justify-between">
              <span className="text-sm text-slate-600">Remaining Budget</span>
              <span className="font-semibold text-slate-900">
                {formatCurrency(Math.max(0, monthlyBudget - totalSpent))}
              </span>
            </div>
            <p className="text-xs text-slate-400 mt-1">
              ~{formatCurrency((monthlyBudget - totalSpent) / 12)}/day for rest of month
            </p>
          </div>
        </div>

        {/* Category Breakdown */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          <h2 className="font-semibold text-slate-900 mb-4">Spending by Category</h2>

          <div className="space-y-4">
            {spendingCategories.map((cat) => {
              const CategoryIcon = cat.icon;
              const percentage = (cat.amount / cat.budget) * 100;
              const isOver = percentage > 100;
              return (
                <div key={cat.category}>
                  <div className="flex items-center justify-between mb-1.5">
                    <div className="flex items-center gap-2">
                      <div className={`w-8 h-8 rounded-lg flex items-center justify-center bg-${cat.color}-100`}>
                        <CategoryIcon className={`w-4 h-4 text-${cat.color}-600`} />
                      </div>
                      <span className="text-sm font-medium text-slate-900">{cat.label}</span>
                    </div>
                    <div className="text-right">
                      <span className="text-sm font-medium text-slate-900">{formatCurrency(cat.amount)}</span>
                      <span className="text-xs text-slate-400 ml-1">/ {formatCurrency(cat.budget)}</span>
                    </div>
                  </div>
                  <div className="w-full bg-slate-100 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full transition-all ${
                        isOver ? 'bg-red-500' : `bg-${cat.color}-500`
                      }`}
                      style={{ width: `${Math.min(percentage, 100)}%` }}
                    />
                  </div>
                  {isOver && (
                    <p className="text-xs text-red-500 mt-1 flex items-center gap-1">
                      <AlertCircle className="w-3 h-3" />
                      Over budget by {formatCurrency(cat.amount - cat.budget)}
                    </p>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Transaction Ledger */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200">
        <div className="p-4 border-b border-slate-200">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <h2 className="font-semibold text-slate-900">Transaction History</h2>
            <div className="flex items-center gap-3">
              {/* Search */}
              <div className="relative">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search transactions..."
                  value={transactionSearch}
                  onChange={(e) => setTransactionSearch(e.target.value)}
                  className="pl-9 pr-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent w-48"
                />
              </div>
              {/* Filter */}
              <select
                value={transactionFilter}
                onChange={(e) => setTransactionFilter(e.target.value as TransactionCategory | 'all')}
                className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
              >
                <option value="all">All Categories</option>
                {Object.entries(categoryConfig).map(([key, config]) => (
                  <option key={key} value={key}>{config.label}</option>
                ))}
              </select>
              {/* Export */}
              <button className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                <Download className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Transactions List */}
        <div className="divide-y divide-slate-100">
          {filteredTransactions.length > 0 ? (
            filteredTransactions.map((transaction) => {
              const CategoryIcon = categoryConfig[transaction.category].icon;
              const statusStyle = getStatusBadge(transaction.status);
              const StatusIcon = statusStyle.icon;
              const isExpanded = expandedTransaction === transaction.id;

              return (
                <div
                  key={transaction.id}
                  className="hover:bg-slate-50 transition-colors"
                >
                  <div
                    className="p-4 cursor-pointer"
                    onClick={() => setExpandedTransaction(isExpanded ? null : transaction.id)}
                  >
                    <div className="flex items-center gap-4">
                      <div className={`w-10 h-10 rounded-lg flex items-center justify-center bg-${categoryConfig[transaction.category].color}-100`}>
                        <CategoryIcon className={`w-5 h-5 text-${categoryConfig[transaction.category].color}-600`} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <p className="font-medium text-slate-900">{transaction.vendor}</p>
                          <span className={`inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full ${statusStyle.bg} ${statusStyle.text}`}>
                            <StatusIcon className="w-3 h-3" />
                            {transaction.status.charAt(0).toUpperCase() + transaction.status.slice(1)}
                          </span>
                        </div>
                        <p className="text-sm text-slate-500 truncate">{transaction.description}</p>
                      </div>
                      <div className="text-right flex-shrink-0">
                        <p className="font-semibold text-slate-900">-{formatCurrency(transaction.amount)}</p>
                        <p className="text-xs text-slate-400">{formatDate(transaction.date)}</p>
                      </div>
                      <ChevronRight className={`w-5 h-5 text-slate-400 transition-transform ${isExpanded ? 'rotate-90' : ''}`} />
                    </div>
                  </div>

                  {/* Expanded Details */}
                  {isExpanded && (
                    <div className="px-4 pb-4">
                      <div className="ml-14 p-4 bg-slate-50 rounded-lg space-y-3">
                        <div className="grid grid-cols-2 gap-4 text-sm">
                          <div>
                            <p className="text-slate-500">Date</p>
                            <p className="font-medium text-slate-900">{formatDateFull(transaction.date)}</p>
                          </div>
                          <div>
                            <p className="text-slate-500">Category</p>
                            <p className="font-medium text-slate-900">{categoryConfig[transaction.category].label}</p>
                          </div>
                          {transaction.paymentMethod && (
                            <div>
                              <p className="text-slate-500">Payment Method</p>
                              <p className="font-medium text-slate-900">{transaction.paymentMethod}</p>
                            </div>
                          )}
                          {transaction.reference && (
                            <div>
                              <p className="text-slate-500">Reference</p>
                              <p className="font-medium text-slate-900">{transaction.reference}</p>
                            </div>
                          )}
                        </div>

                        {/* Action Buttons */}
                        <div className="flex items-center gap-2 pt-2 border-t border-slate-200">
                          {transaction.receiptUrl && (
                            <button
                              onClick={() => setShowReceiptModal(transaction)}
                              className="flex items-center gap-1.5 px-3 py-1.5 bg-white border border-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors"
                            >
                              <Receipt className="w-4 h-4" />
                              View Receipt
                            </button>
                          )}
                          {transaction.status === 'completed' && (
                            <button className="flex items-center gap-1.5 px-3 py-1.5 bg-white border border-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors">
                              <CheckCircle2 className="w-4 h-4" />
                              Verify
                            </button>
                          )}
                          {(transaction.status === 'completed' || transaction.status === 'failed') && (
                            <button className="flex items-center gap-1.5 px-3 py-1.5 bg-white border border-slate-200 text-orange-600 text-sm font-medium rounded-lg hover:bg-orange-50 transition-colors">
                              <AlertTriangle className="w-4 h-4" />
                              Dispute
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              );
            })
          ) : (
            <div className="p-8 text-center text-slate-500">
              <Receipt className="w-12 h-12 mx-auto mb-3 text-slate-300" />
              <p>No transactions found</p>
              <p className="text-sm mt-1">Try adjusting your search or filter</p>
            </div>
          )}
        </div>

        {/* Load More */}
        {filteredTransactions.length > 0 && (
          <div className="p-4 border-t border-slate-200 text-center">
            <button className="text-sm text-emerald-600 font-medium hover:text-emerald-700">
              Load More Transactions
            </button>
          </div>
        )}
      </div>

      {/* Bill Splitter */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <Users className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <h2 className="font-semibold text-slate-900">Bill Splitter</h2>
              <p className="text-sm text-slate-500">Track shared expenses with family</p>
            </div>
          </div>
          <button className="text-sm text-emerald-600 font-medium hover:text-emerald-700">
            + Split Expense
          </button>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {familyMembers.map((member) => (
            <div key={member.id} className="p-4 bg-slate-50 rounded-lg">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center">
                  <span className="text-sm font-semibold text-emerald-700">{member.initials}</span>
                </div>
                <div>
                  <p className="font-medium text-slate-900">{member.name}</p>
                  <p className="text-xs text-slate-500">This month</p>
                </div>
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs text-slate-500">Paid</p>
                  <p className="font-semibold text-green-600">{formatCurrency(member.paidAmount)}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-slate-500">Owes</p>
                  <p className={`font-semibold ${member.owedAmount > 0 ? 'text-red-600' : 'text-slate-900'}`}>
                    {formatCurrency(member.owedAmount)}
                  </p>
                </div>
              </div>
              {member.owedAmount > 0 && (
                <button className="w-full mt-3 px-3 py-1.5 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                  Send Reminder
                </button>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Security Footer */}
      <div className="flex items-center justify-center gap-6 py-4 text-sm text-slate-400">
        <div className="flex items-center gap-2">
          <Lock className="w-4 h-4" />
          <span>Bank-level encryption</span>
        </div>
        <div className="flex items-center gap-2">
          <ShieldCheck className="w-4 h-4" />
          <span>PCI DSS Compliant</span>
        </div>
        <div className="flex items-center gap-2">
          <Eye className="w-4 h-4" />
          <span>Never stores full card numbers</span>
        </div>
      </div>

      {/* Add Funds Modal */}
      {showAddFundsModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowAddFundsModal(false)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-md">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-slate-900">Add Funds to Wallet</h3>
                  <button
                    onClick={() => setShowAddFundsModal(false)}
                    className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                  >
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Amount</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">$</span>
                    <input
                      type="number"
                      placeholder="0.00"
                      className="w-full pl-7 pr-3 py-3 text-lg font-semibold border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                    />
                  </div>
                </div>

                {/* Quick Amounts */}
                <div className="flex gap-2">
                  {[500, 1000, 2000, 5000].map((amount) => (
                    <button
                      key={amount}
                      className="flex-1 py-2 text-sm font-medium text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors"
                    >
                      ${amount.toLocaleString()}
                    </button>
                  ))}
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Payment Method</label>
                  <div className="space-y-2">
                    {paymentMethods.map((method) => (
                      <label
                        key={method.id}
                        className="flex items-center gap-3 p-3 border border-slate-200 rounded-lg cursor-pointer hover:border-emerald-500 transition-colors"
                      >
                        <input
                          type="radio"
                          name="paymentMethod"
                          defaultChecked={method.isDefault}
                          className="text-emerald-600 focus:ring-emerald-500"
                        />
                        <div className="flex items-center gap-2 flex-1">
                          {method.type === 'card' ? (
                            <CreditCard className="w-5 h-5 text-slate-400" />
                          ) : (
                            <Building className="w-5 h-5 text-slate-400" />
                          )}
                          <span className="font-medium text-slate-900">
                            {method.type === 'card' ? method.brand : method.bankName} •••• {method.last4}
                          </span>
                        </div>
                        {method.isDefault && (
                          <span className="text-xs bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded">Default</span>
                        )}
                      </label>
                    ))}
                  </div>
                </div>
              </div>

              <div className="p-6 border-t border-slate-200">
                <button className="w-full py-3 bg-emerald-600 text-white font-semibold rounded-lg hover:bg-emerald-700 transition-colors">
                  Add Funds
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Manage Cards Modal */}
      {showManageCardsModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowManageCardsModal(false)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-md">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-slate-900">Payment Methods</h3>
                  <button
                    onClick={() => setShowManageCardsModal(false)}
                    className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                  >
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6 space-y-4">
                {paymentMethods.map((method) => (
                  <div
                    key={method.id}
                    className="flex items-center gap-4 p-4 border border-slate-200 rounded-lg"
                  >
                    <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${
                      method.type === 'card' ? 'bg-blue-100' : 'bg-green-100'
                    }`}>
                      {method.type === 'card' ? (
                        <CreditCard className="w-6 h-6 text-blue-600" />
                      ) : (
                        <Building className="w-6 h-6 text-green-600" />
                      )}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-slate-900">
                        {method.type === 'card' ? method.brand : method.bankName} •••• {method.last4}
                      </p>
                      {method.expiresAt && (
                        <p className="text-sm text-slate-500">Expires {method.expiresAt}</p>
                      )}
                    </div>
                    {method.isDefault ? (
                      <span className="text-xs bg-emerald-100 text-emerald-700 px-2 py-1 rounded">Default</span>
                    ) : (
                      <button className="text-sm text-slate-500 hover:text-slate-700">Set Default</button>
                    )}
                  </div>
                ))}

                <button className="w-full flex items-center justify-center gap-2 py-3 border-2 border-dashed border-slate-300 rounded-lg text-slate-600 hover:border-emerald-500 hover:text-emerald-600 transition-colors">
                  <Plus className="w-5 h-5" />
                  <span className="font-medium">Add Payment Method</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Receipt Modal */}
      {showReceiptModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowReceiptModal(null)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-md">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-slate-900">Receipt</h3>
                  <button
                    onClick={() => setShowReceiptModal(null)}
                    className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                  >
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6">
                {/* Receipt Content */}
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-3">
                    <Receipt className="w-8 h-8 text-emerald-600" />
                  </div>
                  <p className="font-semibold text-slate-900">{showReceiptModal.vendor}</p>
                  <p className="text-sm text-slate-500">{showReceiptModal.description}</p>
                </div>

                <div className="space-y-3 mb-6">
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Amount</span>
                    <span className="font-medium text-slate-900">{formatCurrency(showReceiptModal.amount)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Date</span>
                    <span className="font-medium text-slate-900">{formatDateFull(showReceiptModal.date)}</span>
                  </div>
                  {showReceiptModal.reference && (
                    <div className="flex justify-between text-sm">
                      <span className="text-slate-500">Reference</span>
                      <span className="font-medium text-slate-900">{showReceiptModal.reference}</span>
                    </div>
                  )}
                  {showReceiptModal.paymentMethod && (
                    <div className="flex justify-between text-sm">
                      <span className="text-slate-500">Payment Method</span>
                      <span className="font-medium text-slate-900">{showReceiptModal.paymentMethod}</span>
                    </div>
                  )}
                </div>

                {/* Receipt Preview Placeholder */}
                <div className="bg-slate-100 rounded-lg p-8 text-center mb-4">
                  <FileText className="w-12 h-12 text-slate-400 mx-auto mb-2" />
                  <p className="text-sm text-slate-500">Receipt document preview</p>
                </div>

                <div className="flex gap-3">
                  <button className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                    <Download className="w-4 h-4" />
                    Download
                  </button>
                  <button className="flex-1 flex items-center justify-center gap-2 py-2.5 border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors">
                    <Eye className="w-4 h-4" />
                    Full View
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Approval Detail Modal */}
      {showApprovalDetail && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowApprovalDetail(null)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-lg">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-slate-900">Payment Approval</h3>
                  <button
                    onClick={() => setShowApprovalDetail(null)}
                    className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                  >
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6">
                <div className="flex items-start gap-4 mb-6">
                  <div className={`w-14 h-14 rounded-xl flex items-center justify-center bg-${categoryConfig[showApprovalDetail.category].color}-100`}>
                    {(() => {
                      const CategoryIcon = categoryConfig[showApprovalDetail.category].icon;
                      return <CategoryIcon className={`w-7 h-7 text-${categoryConfig[showApprovalDetail.category].color}-600`} />;
                    })()}
                  </div>
                  <div>
                    <p className="font-semibold text-lg text-slate-900">{showApprovalDetail.vendor}</p>
                    <p className="text-slate-500">{showApprovalDetail.description}</p>
                    <span className={`inline-block mt-2 text-xs px-2 py-0.5 rounded-full ${getUrgencyBadge(showApprovalDetail.urgency)}`}>
                      {showApprovalDetail.urgency === 'high' ? 'Urgent' : showApprovalDetail.urgency === 'medium' ? 'Due Soon' : 'Normal Priority'}
                    </span>
                  </div>
                </div>

                <div className="bg-slate-50 rounded-lg p-4 mb-6">
                  <div className="flex items-center justify-between">
                    <span className="text-slate-600">Amount</span>
                    <span className="text-2xl font-bold text-slate-900">{formatCurrency(showApprovalDetail.amount)}</span>
                  </div>
                </div>

                {showApprovalDetail.managerNote && (
                  <div className="bg-emerald-50 border border-emerald-200 rounded-lg p-4 mb-6">
                    <div className="flex items-start gap-3">
                      <Sparkles className="w-5 h-5 text-emerald-600 flex-shrink-0 mt-0.5" />
                      <div>
                        <p className="font-medium text-emerald-900">Manager's Note</p>
                        <p className="text-sm text-emerald-700 mt-1">{showApprovalDetail.managerNote}</p>
                      </div>
                    </div>
                  </div>
                )}

                <div className="space-y-3 mb-6">
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Category</span>
                    <span className="font-medium text-slate-900">{categoryConfig[showApprovalDetail.category].label}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Requested</span>
                    <span className="font-medium text-slate-900">{formatDateFull(showApprovalDetail.requestedAt)}</span>
                  </div>
                  {showApprovalDetail.dueDate && (
                    <div className="flex justify-between text-sm">
                      <span className="text-slate-500">Due Date</span>
                      <span className="font-medium text-slate-900">{formatDateFull(showApprovalDetail.dueDate)}</span>
                    </div>
                  )}
                </div>

                <div className="flex gap-3">
                  <button
                    onClick={() => {
                      handleApprove(showApprovalDetail);
                      setShowApprovalDetail(null);
                    }}
                    className="flex-1 flex items-center justify-center gap-2 py-3 bg-emerald-600 text-white font-semibold rounded-lg hover:bg-emerald-700 transition-colors"
                  >
                    <Check className="w-5 h-5" />
                    Approve Payment
                  </button>
                  <button
                    onClick={() => {
                      handleReject(showApprovalDetail);
                      setShowApprovalDetail(null);
                    }}
                    className="flex-1 flex items-center justify-center gap-2 py-3 border border-slate-200 text-slate-700 font-semibold rounded-lg hover:bg-slate-50 transition-colors"
                  >
                    <X className="w-5 h-5" />
                    Decline
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Mobile FAB */}
      <div className="fixed bottom-6 right-6 sm:hidden">
        <button
          onClick={() => setShowAddFundsModal(true)}
          className="w-14 h-14 bg-emerald-600 text-white rounded-full shadow-lg flex items-center justify-center hover:bg-emerald-700 transition-colors"
        >
          <Plus className="w-6 h-6" />
        </button>
      </div>
    </div>
  );
}
