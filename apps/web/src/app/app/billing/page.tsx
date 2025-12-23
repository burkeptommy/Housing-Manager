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
  ChevronUp,
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
  Users,
  PawPrint,
  GraduationCap,
  Car,
  Umbrella,
  Wifi,
  Droplets,
  Flame,
  Printer,
  ExternalLink,
  Info,
  BadgeCheck,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type BillCategory =
  | 'membership'
  | 'mortgage'
  | 'utilities'
  | 'insurance'
  | 'household_services'
  | 'kids_activities'
  | 'childcare'
  | 'pet_care'
  | 'maintenance';

type PaymentStatus = 'paid' | 'scheduled' | 'due_soon' | 'overdue' | 'pending';

interface BillItem {
  id: string;
  vendor: string;
  description: string;
  amount: number;
  category: BillCategory;
  status: PaymentStatus;
  paidDate?: Date;
  dueDate?: Date;
  isRecurring?: boolean;
  frequency?: string;
  accountNumber?: string;
}

interface MortgageDetails {
  lender: string;
  accountNumber: string;
  monthlyPayment: number;
  principalAndInterest: number;
  escrowAmount: number;
  loanBalance: number;
  interestRate: number;
  payoffDate: Date;
  lastPaidDate: Date;
  nextDueDate: Date;
}

interface AuthorizationRequest {
  id: string;
  vendor: string;
  description: string;
  amount: number;
  category: BillCategory;
  date: Date;
  urgency: 'low' | 'medium' | 'high';
  managerNote: string;
  managerName: string;
}

interface StatementBreakdown {
  membership: number;
  mortgage: number;
  utilities: number;
  insurance: number;
  householdServices: number;
  kidsActivities: number;
  childcare: number;
  petCare: number;
  maintenance: number;
  total: number;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const HAVEN_MEMBERSHIP_FEE = 149;

const MOCK_MORTGAGE: MortgageDetails = {
  lender: 'First National Bank',
  accountNumber: '****4521',
  monthlyPayment: 3200,
  principalAndInterest: 2850,
  escrowAmount: 350,
  loanBalance: 412500,
  interestRate: 6.875,
  payoffDate: new Date(2054, 0, 1),
  lastPaidDate: new Date(2024, 11, 1),
  nextDueDate: new Date(2025, 0, 1),
};

const generateMockBills = (): BillItem[] => {
  const now = new Date();
  const thisMonth = now.getMonth();
  const thisYear = now.getFullYear();

  return [
    // Mortgage & Housing
    {
      id: 'bill-m1',
      vendor: 'First National Bank',
      description: 'Mortgage payment',
      amount: 2850,
      category: 'mortgage',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 1),
      isRecurring: true,
      frequency: 'Monthly',
    },
    {
      id: 'bill-m2',
      vendor: 'County Tax Office',
      description: 'Property tax (escrow)',
      amount: 350,
      category: 'mortgage',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 1),
      isRecurring: true,
      frequency: 'Included',
    },

    // Utilities
    {
      id: 'bill-u1',
      vendor: 'ConEd',
      description: 'Electric',
      amount: 187.43,
      category: 'utilities',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 15),
      isRecurring: true,
    },
    {
      id: 'bill-u2',
      vendor: 'National Grid',
      description: 'Natural gas',
      amount: 94.50,
      category: 'utilities',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 12),
      isRecurring: true,
    },
    {
      id: 'bill-u3',
      vendor: 'City Water Authority',
      description: 'Water & sewer',
      amount: 78.50,
      category: 'utilities',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 10),
      isRecurring: true,
    },
    {
      id: 'bill-u4',
      vendor: 'Verizon Fios',
      description: 'Internet (1 Gbps)',
      amount: 187.50,
      category: 'utilities',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 8),
      isRecurring: true,
    },

    // Insurance
    {
      id: 'bill-i1',
      vendor: 'State Farm',
      description: 'Homeowners premium',
      amount: 312,
      category: 'insurance',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 11),
      isRecurring: true,
      frequency: 'Monthly',
    },
    {
      id: 'bill-i2',
      vendor: 'Geico',
      description: 'Auto insurance',
      amount: 156,
      category: 'insurance',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 15),
      isRecurring: true,
      frequency: 'Monthly',
    },
    {
      id: 'bill-i3',
      vendor: 'Chubb',
      description: 'Umbrella policy',
      amount: 0,
      category: 'insurance',
      status: 'paid',
      paidDate: new Date(thisYear, 5, 1),
      isRecurring: true,
      frequency: 'Paid annually',
    },

    // Household Services
    {
      id: 'bill-s1',
      vendor: 'CleanPro Services',
      description: 'House cleaning',
      amount: 360,
      category: 'household_services',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 14),
      isRecurring: true,
      frequency: 'Bi-weekly',
    },
    {
      id: 'bill-s2',
      vendor: 'Green Thumb Landscaping',
      description: 'Lawn care',
      amount: 175,
      category: 'household_services',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 14),
      isRecurring: true,
      frequency: 'Weekly',
    },
    {
      id: 'bill-s3',
      vendor: 'Crystal Clear Pools',
      description: 'Pool service',
      amount: 175,
      category: 'household_services',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 10),
      isRecurring: true,
      frequency: 'Weekly',
    },
    {
      id: 'bill-s4',
      vendor: 'Bug-Free Pest Control',
      description: 'Quarterly pest treatment',
      amount: 185,
      category: 'household_services',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 5),
      isRecurring: true,
      frequency: 'Quarterly',
    },

    // Kids & Activities
    {
      id: 'bill-k1',
      vendor: 'Westlake Middle School',
      description: 'Tuition - Emma',
      amount: 2200,
      category: 'kids_activities',
      status: 'due_soon',
      dueDate: new Date(thisYear, thisMonth, now.getDate() + 5),
      isRecurring: true,
      frequency: 'Monthly',
    },
    {
      id: 'bill-k2',
      vendor: 'Austin FC Youth',
      description: 'Travel soccer - Emma',
      amount: 350,
      category: 'kids_activities',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 1),
      isRecurring: true,
      frequency: 'Monthly',
    },
    {
      id: 'bill-k3',
      vendor: 'Harmony Music Academy',
      description: 'Piano lessons - Jake',
      amount: 200,
      category: 'kids_activities',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 5),
      isRecurring: true,
      frequency: 'Monthly',
    },
    {
      id: 'bill-k4',
      vendor: 'Creative Arts Studio',
      description: 'Art class - Jake',
      amount: 25,
      category: 'kids_activities',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 3),
      isRecurring: true,
      frequency: 'Weekly',
    },

    // Pet Care
    {
      id: 'bill-p1',
      vendor: 'Blue Buffalo',
      description: 'Dog food (auto-ship)',
      amount: 150,
      category: 'pet_care',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 8),
      isRecurring: true,
      frequency: 'Monthly',
    },

    // Maintenance (one-time or recent)
    {
      id: 'bill-x1',
      vendor: 'HandyPro Services',
      description: 'Garbage disposal replacement',
      amount: 62.30,
      category: 'maintenance',
      status: 'paid',
      paidDate: new Date(thisYear, thisMonth, 14),
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
      managerNote: 'Urgent - Pipe burst in kitchen. Vendor is on-site and waiting for approval. I recommend approving immediately to prevent water damage to cabinets.',
      managerName: 'Sarah',
    },
    {
      id: 'auth-2',
      vendor: 'Ace Roofing Co.',
      description: 'Roof inspection and shingle replacement',
      amount: 875,
      category: 'maintenance',
      date: new Date(thisYear, thisMonth, now.getDate() - 1, 10, 0),
      urgency: 'medium',
      managerNote: 'Recommended after last storm. I obtained 3 quotes - this is the best value ($875 vs $1,200 and $950). Happy to discuss alternatives.',
      managerName: 'Sarah',
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
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};

const formatFullDate = (date: Date) => {
  return date.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
};

const getCategoryIcon = (category: BillCategory) => {
  switch (category) {
    case 'mortgage': return Home;
    case 'utilities': return Zap;
    case 'insurance': return ShieldCheck;
    case 'household_services': return Sparkles;
    case 'kids_activities': return GraduationCap;
    case 'childcare': return Users;
    case 'pet_care': return PawPrint;
    case 'maintenance': return Wrench;
    case 'membership': return Receipt;
    default: return DollarSign;
  }
};

const getCategoryColor = (category: BillCategory) => {
  switch (category) {
    case 'mortgage': return { bg: 'bg-indigo-100', text: 'text-indigo-700', icon: 'text-indigo-600', border: 'border-indigo-200' };
    case 'utilities': return { bg: 'bg-amber-100', text: 'text-amber-700', icon: 'text-amber-600', border: 'border-amber-200' };
    case 'insurance': return { bg: 'bg-emerald-100', text: 'text-emerald-700', icon: 'text-emerald-600', border: 'border-emerald-200' };
    case 'household_services': return { bg: 'bg-purple-100', text: 'text-purple-700', icon: 'text-purple-600', border: 'border-purple-200' };
    case 'kids_activities': return { bg: 'bg-pink-100', text: 'text-pink-700', icon: 'text-pink-600', border: 'border-pink-200' };
    case 'childcare': return { bg: 'bg-rose-100', text: 'text-rose-700', icon: 'text-rose-600', border: 'border-rose-200' };
    case 'pet_care': return { bg: 'bg-orange-100', text: 'text-orange-700', icon: 'text-orange-600', border: 'border-orange-200' };
    case 'maintenance': return { bg: 'bg-blue-100', text: 'text-blue-700', icon: 'text-blue-600', border: 'border-blue-200' };
    case 'membership': return { bg: 'bg-slate-100', text: 'text-slate-700', icon: 'text-slate-600', border: 'border-slate-200' };
    default: return { bg: 'bg-slate-100', text: 'text-slate-700', icon: 'text-slate-600', border: 'border-slate-200' };
  }
};

const getCategoryLabel = (category: BillCategory) => {
  switch (category) {
    case 'mortgage': return 'Mortgage & Housing';
    case 'utilities': return 'Utilities';
    case 'insurance': return 'Insurance';
    case 'household_services': return 'Household Services';
    case 'kids_activities': return 'Kids & Activities';
    case 'childcare': return 'Childcare';
    case 'pet_care': return 'Pet Care';
    case 'maintenance': return 'Maintenance & Repairs';
    case 'membership': return 'Haven Membership';
    default: return 'Other';
  }
};

const getStatusBadge = (status: PaymentStatus, dueDate?: Date) => {
  switch (status) {
    case 'paid':
      return <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full"><CheckCircle2 className="w-3 h-3" /> Paid</span>;
    case 'scheduled':
      return <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-blue-100 text-blue-700 text-xs font-medium rounded-full"><Clock className="w-3 h-3" /> Scheduled</span>;
    case 'due_soon':
      const daysUntil = dueDate ? Math.ceil((dueDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24)) : 0;
      return <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded-full"><AlertTriangle className="w-3 h-3" /> Due in {daysUntil} days</span>;
    case 'overdue':
      return <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-red-100 text-red-700 text-xs font-medium rounded-full"><AlertCircle className="w-3 h-3" /> Overdue</span>;
    default:
      return <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-slate-100 text-slate-700 text-xs font-medium rounded-full">Pending</span>;
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
        request.urgency === 'high' ? 'border-red-300 bg-red-50/30' : 'border-slate-200'
      }`}
    >
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
          Approve
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

function MortgageCard({ mortgage }: { mortgage: MortgageDetails }) {
  const [showDetails, setShowDetails] = useState(false);

  return (
    <div className="bg-white rounded-2xl border border-indigo-200 shadow-sm overflow-hidden">
      <div className="p-5 bg-gradient-to-r from-indigo-50 to-indigo-100/50">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-indigo-200 rounded-xl">
              <Home className="w-6 h-6 text-indigo-700" />
            </div>
            <div>
              <h3 className="font-semibold text-slate-900">Mortgage & Housing</h3>
              <p className="text-sm text-slate-600">{mortgage.lender}</p>
            </div>
          </div>
          <div className="text-right">
            <div className="text-2xl font-bold text-slate-900">{formatCurrency(mortgage.monthlyPayment)}</div>
            <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
              <CheckCircle2 className="w-3 h-3" /> Paid {formatDate(mortgage.lastPaidDate)}
            </span>
          </div>
        </div>
      </div>

      <div className="p-5 space-y-3">
        <div className="flex items-center justify-between py-2 border-b border-slate-100">
          <span className="text-sm text-slate-600">Principal & Interest</span>
          <span className="font-medium text-slate-900">{formatCurrency(mortgage.principalAndInterest)}</span>
        </div>
        <div className="flex items-center justify-between py-2 border-b border-slate-100">
          <span className="text-sm text-slate-600">Property Tax (Escrow)</span>
          <span className="font-medium text-slate-900">{formatCurrency(mortgage.escrowAmount)}</span>
        </div>
        <div className="flex items-center justify-between py-2">
          <span className="text-sm text-slate-600">Next Payment</span>
          <span className="text-sm font-medium text-blue-600">{formatDate(mortgage.nextDueDate)} - Scheduled</span>
        </div>
      </div>

      <button
        onClick={() => setShowDetails(!showDetails)}
        className="w-full flex items-center justify-center gap-2 py-3 border-t border-slate-100 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
      >
        {showDetails ? (
          <>
            <ChevronUp className="w-4 h-4" />
            Hide Loan Details
          </>
        ) : (
          <>
            <ChevronDown className="w-4 h-4" />
            View Loan Details
          </>
        )}
      </button>

      {showDetails && (
        <div className="p-5 bg-slate-50 border-t border-slate-100 space-y-3">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-slate-500">Loan Balance</p>
              <p className="font-semibold text-slate-900">{formatCurrency(mortgage.loanBalance)}</p>
            </div>
            <div>
              <p className="text-xs text-slate-500">Interest Rate</p>
              <p className="font-semibold text-slate-900">{mortgage.interestRate}%</p>
            </div>
            <div>
              <p className="text-xs text-slate-500">Account Number</p>
              <p className="font-semibold text-slate-900">{mortgage.accountNumber}</p>
            </div>
            <div>
              <p className="text-xs text-slate-500">Estimated Payoff</p>
              <p className="font-semibold text-slate-900">{mortgage.payoffDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function BillCategoryGroup({
  category,
  bills,
  isExpanded,
  onToggle,
}: {
  category: BillCategory;
  bills: BillItem[];
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const CategoryIcon = getCategoryIcon(category);
  const categoryColor = getCategoryColor(category);
  const total = bills.reduce((sum, bill) => sum + bill.amount, 0);
  const hasDueSoon = bills.some(b => b.status === 'due_soon' || b.status === 'overdue');

  return (
    <div className={`bg-white rounded-xl border ${hasDueSoon ? 'border-amber-300' : 'border-slate-200'} overflow-hidden`}>
      <button
        onClick={onToggle}
        className="w-full flex items-center justify-between p-4 hover:bg-slate-50 transition-colors"
      >
        <div className="flex items-center gap-3">
          <div className={`p-2 rounded-lg ${categoryColor.bg}`}>
            <CategoryIcon className={`w-5 h-5 ${categoryColor.icon}`} />
          </div>
          <div className="text-left">
            <div className="flex items-center gap-2">
              <span className="font-medium text-slate-900">{getCategoryLabel(category)}</span>
              {hasDueSoon && <AlertTriangle className="w-4 h-4 text-amber-500" />}
            </div>
            <div className="text-sm text-slate-500">{bills.length} {bills.length === 1 ? 'item' : 'items'}</div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <span className="font-semibold text-slate-900">{formatCurrency(total)}</span>
          <ChevronDown className={`w-5 h-5 text-slate-400 transition-transform ${isExpanded ? 'rotate-180' : ''}`} />
        </div>
      </button>

      {isExpanded && (
        <div className="px-4 pb-4">
          <div className="border-t border-slate-100 pt-3 space-y-2">
            {bills.map((bill) => (
              <div
                key={bill.id}
                className={`flex items-center justify-between p-3 rounded-lg ${
                  bill.status === 'due_soon' ? 'bg-amber-50 border border-amber-200' : 'bg-slate-50'
                }`}
              >
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-slate-900">{bill.vendor}</span>
                    {bill.isRecurring && bill.frequency && (
                      <span className="px-1.5 py-0.5 text-[10px] font-medium bg-slate-200 text-slate-600 rounded">
                        {bill.frequency}
                      </span>
                    )}
                  </div>
                  <div className="text-sm text-slate-500">{bill.description}</div>
                </div>
                <div className="text-right">
                  <div className="font-medium text-slate-900">{formatCurrency(bill.amount)}</div>
                  <div className="mt-1">
                    {bill.status === 'paid' && bill.paidDate ? (
                      <span className="text-xs text-emerald-600">Paid {formatDate(bill.paidDate)}</span>
                    ) : (
                      getStatusBadge(bill.status, bill.dueDate)
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
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
  const [mortgage] = useState<MortgageDetails>(MOCK_MORTGAGE);

  const [showConfetti, setShowConfetti] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);
  const [showStatementModal, setShowStatementModal] = useState(false);
  const [showThresholdModal, setShowThresholdModal] = useState(false);
  const [trustThreshold, setTrustThreshold] = useState(200);
  const [tempThreshold, setTempThreshold] = useState(200);

  // Category expansion state
  const [expandedCategories, setExpandedCategories] = useState<Set<BillCategory>>(new Set(['utilities', 'kids_activities']));

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
    showToast('Approved! Sarah will proceed.', 'success');
  }, []);

  const handleDecline = useCallback((id: string) => {
    setAuthRequests((prev) => prev.filter((req) => req.id !== id));
    showToast('Declined. Sarah has been notified.', 'info');
  }, []);

  // Toggle category expansion
  const toggleCategory = (category: BillCategory) => {
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
  const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long' });
  const currentYear = new Date().getFullYear();

  const statementBreakdown: StatementBreakdown = useMemo(() => {
    const membership = HAVEN_MEMBERSHIP_FEE;
    const mortgageTotal = bills.filter(b => b.category === 'mortgage').reduce((s, b) => s + b.amount, 0);
    const utilities = bills.filter(b => b.category === 'utilities').reduce((s, b) => s + b.amount, 0);
    const insurance = bills.filter(b => b.category === 'insurance').reduce((s, b) => s + b.amount, 0);
    const householdServices = bills.filter(b => b.category === 'household_services').reduce((s, b) => s + b.amount, 0);
    const kidsActivities = bills.filter(b => b.category === 'kids_activities').reduce((s, b) => s + b.amount, 0);
    const childcare = bills.filter(b => b.category === 'childcare').reduce((s, b) => s + b.amount, 0);
    const petCare = bills.filter(b => b.category === 'pet_care').reduce((s, b) => s + b.amount, 0);
    const maintenance = bills.filter(b => b.category === 'maintenance').reduce((s, b) => s + b.amount, 0);

    return {
      membership,
      mortgage: mortgageTotal,
      utilities,
      insurance,
      householdServices,
      kidsActivities,
      childcare,
      petCare,
      maintenance,
      total: membership + mortgageTotal + utilities + insurance + householdServices + kidsActivities + childcare + petCare + maintenance,
    };
  }, [bills]);

  const billsByCategory = useMemo(() => {
    const grouped: Record<BillCategory, BillItem[]> = {
      membership: [],
      mortgage: [],
      utilities: [],
      insurance: [],
      household_services: [],
      kids_activities: [],
      childcare: [],
      pet_care: [],
      maintenance: [],
    };
    bills.forEach((bill) => {
      grouped[bill.category].push(bill);
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

  // Calculate YTD (mock - multiply by 11 months + this month)
  const ytdTotal = statementBreakdown.total * 11;

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
            <div className="flex-1">
              <div className="flex items-center gap-2 text-emerald-400 text-sm font-medium mb-2">
                <Receipt className="w-4 h-4" />
                Your {currentMonth} Statement
              </div>
              <h1 className="text-4xl lg:text-5xl font-bold mb-2 text-white">
                {formatCurrency(statementBreakdown.total)}
              </h1>
              <p className="text-slate-400 mb-6">
                Due {formatFullDate(nextPaymentDate)} • {daysUntilDue} days
              </p>

              {/* Breakdown Table */}
              <div className="bg-white/5 rounded-xl p-4 mb-6 border border-white/10">
                <div className="space-y-2.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-300 flex items-center gap-2">
                      <Receipt className="w-4 h-4 text-slate-500" />
                      Haven Membership
                    </span>
                    <span className="font-medium">{formatCurrency(statementBreakdown.membership)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-300 flex items-center gap-2">
                      <Home className="w-4 h-4 text-indigo-400" />
                      Mortgage & Housing
                    </span>
                    <span className="font-medium">{formatCurrency(statementBreakdown.mortgage)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-300 flex items-center gap-2">
                      <Zap className="w-4 h-4 text-amber-400" />
                      Utilities
                    </span>
                    <span className="font-medium">{formatCurrency(statementBreakdown.utilities)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-300 flex items-center gap-2">
                      <ShieldCheck className="w-4 h-4 text-emerald-400" />
                      Insurance
                    </span>
                    <span className="font-medium">{formatCurrency(statementBreakdown.insurance)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-300 flex items-center gap-2">
                      <Sparkles className="w-4 h-4 text-purple-400" />
                      Household Services
                    </span>
                    <span className="font-medium">{formatCurrency(statementBreakdown.householdServices)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-300 flex items-center gap-2">
                      <GraduationCap className="w-4 h-4 text-pink-400" />
                      Kids & Activities
                    </span>
                    <span className="font-medium">{formatCurrency(statementBreakdown.kidsActivities)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-300 flex items-center gap-2">
                      <PawPrint className="w-4 h-4 text-orange-400" />
                      Pet Care
                    </span>
                    <span className="font-medium">{formatCurrency(statementBreakdown.petCare)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-300 flex items-center gap-2">
                      <Wrench className="w-4 h-4 text-blue-400" />
                      Maintenance & Repairs
                    </span>
                    <span className="font-medium">{formatCurrency(statementBreakdown.maintenance)}</span>
                  </div>
                  <div className="border-t border-white/10 pt-3 mt-3 flex items-center justify-between font-semibold">
                    <span>Total Due January 1</span>
                    <span className="text-emerald-400 text-lg">{formatCurrency(statementBreakdown.total)}</span>
                  </div>
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
                  <BadgeCheck className="w-5 h-5 text-emerald-400" />
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
                Haven pays all your bills throughout the month, then charges you once on the 1st. No action needed.
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
                    <AlertCircle className="w-5 h-5 text-amber-500" />
                    <h2 className="text-lg font-semibold text-slate-900">Sarah Needs Your Approval</h2>
                    <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-semibold rounded-full">
                      {authRequests.length}
                    </span>
                  </div>
                  <button
                    onClick={() => {
                      setTempThreshold(trustThreshold);
                      setShowThresholdModal(true);
                    }}
                    className="text-sm text-slate-500 hover:text-slate-700 font-medium flex items-center gap-1"
                  >
                    <Settings className="w-4 h-4" />
                    Auto-approve under {formatCurrency(trustThreshold)}
                  </button>
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

            {/* Mortgage Section */}
            <div>
              <h2 className="text-lg font-semibold text-slate-900 mb-4">This Month&apos;s Bills</h2>
              <MortgageCard mortgage={mortgage} />
            </div>

            {/* Bills by Category */}
            <div className="space-y-3">
              {(Object.entries(billsByCategory) as [BillCategory, BillItem[]][])
                .filter(([category, categoryBills]) => categoryBills.length > 0 && category !== 'mortgage' && category !== 'membership')
                .map(([category, categoryBills]) => (
                  <BillCategoryGroup
                    key={category}
                    category={category}
                    bills={categoryBills}
                    isExpanded={expandedCategories.has(category)}
                    onToggle={() => toggleCategory(category)}
                  />
                ))}
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Annual Summary */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 bg-purple-100 rounded-lg">
                  <TrendingUp className="w-5 h-5 text-purple-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-slate-900">{currentYear} Summary</h3>
                  <p className="text-sm text-slate-500">Year-to-date spending</p>
                </div>
              </div>

              <div className="p-4 bg-slate-50 rounded-lg mb-4">
                <div className="text-center">
                  <div className="text-3xl font-bold text-slate-900">{formatCurrency(ytdTotal)}</div>
                  <div className="text-sm text-slate-500 mt-1">Total paid by Haven this year</div>
                </div>
              </div>

              <button
                onClick={() => showToast('Opening annual summary...', 'info')}
                className="w-full flex items-center justify-center gap-2 px-4 py-2.5 bg-purple-600 text-white rounded-lg font-medium hover:bg-purple-700 transition-colors"
              >
                View Full Report
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>

            {/* Bill Accounts */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-slate-900">Bill Accounts</h3>
                <span className="text-xs text-slate-500">12 linked</span>
              </div>

              <p className="text-sm text-slate-600 mb-4">
                Haven pays these bills on your behalf and includes them in your monthly statement.
              </p>

              <button
                onClick={() => showToast('Opening bill account management...', 'info')}
                className="w-full flex items-center justify-center gap-2 py-2.5 border-2 border-dashed border-slate-300 rounded-lg text-slate-600 hover:border-emerald-500 hover:text-emerald-600 transition-colors"
              >
                <Settings className="w-4 h-4" />
                <span className="text-sm font-medium">Manage Accounts</span>
              </button>
            </div>

            {/* Payment Method */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-slate-900">Payment Method</h3>
                <button className="text-sm text-emerald-600 font-medium">Change</button>
              </div>

              <div className="p-4 bg-slate-50 rounded-lg flex items-center gap-4">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <Building2 className="w-5 h-5 text-blue-600" />
                </div>
                <div className="flex-1">
                  <div className="font-medium text-slate-900">Chase Checking</div>
                  <div className="text-sm text-slate-500">•••• 9876</div>
                </div>
                <BadgeCheck className="w-5 h-5 text-emerald-500" />
              </div>
            </div>

            {/* Tax Documents */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 bg-slate-100 rounded-lg">
                  <FileText className="w-5 h-5 text-slate-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-slate-900">Tax Documents</h3>
                  <p className="text-sm text-slate-500">Download for your records</p>
                </div>
              </div>

              <div className="space-y-2">
                <button
                  onClick={() => showToast('Downloading 2024 tax summary...', 'info')}
                  className="w-full flex items-center justify-between p-3 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors"
                >
                  <span className="text-sm font-medium text-slate-700">2024 Tax Summary</span>
                  <Download className="w-4 h-4 text-slate-400" />
                </button>
                <button
                  onClick={() => showToast('Downloading property tax records...', 'info')}
                  className="w-full flex items-center justify-between p-3 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors"
                >
                  <span className="text-sm font-medium text-slate-700">Property Tax Records</span>
                  <Download className="w-4 h-4 text-slate-400" />
                </button>
              </div>
            </div>

            {/* How It Works */}
            <div className="bg-gradient-to-br from-emerald-600 to-emerald-700 rounded-2xl p-6 text-white">
              <div className="flex items-start gap-3 mb-4">
                <div className="p-2 bg-white/20 rounded-lg">
                  <Wallet className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-semibold mb-1 text-white">One Bill, Zero Hassle</h3>
                  <p className="text-sm text-emerald-100">
                    Haven pays ALL your household bills - mortgage, utilities, insurance, services, activities - then sends you one simple statement.
                  </p>
                </div>
              </div>
              <button
                onClick={() => showToast('Opening guide...', 'info')}
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
              {/* Statement content - grouped by category */}
              {(Object.entries(billsByCategory) as [BillCategory, BillItem[]][])
                .filter(([, categoryBills]) => categoryBills.length > 0)
                .map(([category, categoryBills]) => {
                  const CategoryIcon = getCategoryIcon(category);
                  const categoryColor = getCategoryColor(category);
                  const categoryTotal = categoryBills.reduce((s, b) => s + b.amount, 0);

                  if (category === 'membership') {
                    return (
                      <div key={category} className="mb-6">
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
                    );
                  }

                  return (
                    <div key={category} className="mb-6">
                      <div className="flex items-center justify-between mb-3">
                        <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider">
                          {getCategoryLabel(category)}
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
                              {bill.paidDate && (
                                <div className="text-xs text-slate-400">{formatDate(bill.paidDate)}</div>
                              )}
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
                Sarah can automatically approve routine expenses under this amount without asking you first.
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
