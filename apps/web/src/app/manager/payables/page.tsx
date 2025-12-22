'use client';

import { useState } from 'react';
import {
  CreditCard,
  Building2,
  Zap,
  Shield,
  Heart,
  GraduationCap,
  Trophy,
  Dog,
  Wrench,
  AlertTriangle,
  Clock,
  CheckCircle2,
  Calendar,
  ChevronDown,
  ChevronRight,
  X,
  FileText,
  ExternalLink,
  Settings,
  BarChart3,
  Send,
  Plus,
  Upload,
  Link2,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type BillCategory = 'mortgage' | 'utilities' | 'insurance' | 'childcare' | 'education' | 'activities' | 'pet' | 'services';
type BillStatus = 'paid' | 'scheduled' | 'due_soon' | 'overdue' | 'pending_approval';
type ViewMode = 'by_due_date' | 'by_household' | 'all';

interface Bill {
  id: string;
  vendorName: string;
  category: BillCategory;
  amount: number;
  dueDate: string;
  status: BillStatus;
  householdId: string;
  householdName: string;
  accountNumber?: string;
  autoPay: boolean;
  billUrl?: string;
  notes?: string;
}

interface PaymentAccount {
  id: string;
  name: string;
  type: 'operating' | 'float';
  balance: number;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const mockBills: Bill[] = [
  // Overdue
  {
    id: 'bill1',
    vendorName: 'ConEd Electric',
    category: 'utilities',
    amount: 187.43,
    dueDate: 'Dec 18',
    status: 'overdue',
    householdId: 'hh1',
    householdName: 'Smith Family',
    accountNumber: '****4521',
    autoPay: false,
  },
  {
    id: 'bill2',
    vendorName: 'National Grid Gas',
    category: 'utilities',
    amount: 94.50,
    dueDate: 'Dec 19',
    status: 'overdue',
    householdId: 'hh1',
    householdName: 'Smith Family',
    accountNumber: '****8834',
    autoPay: false,
  },
  // Due This Week
  {
    id: 'bill3',
    vendorName: 'Westlake Middle School',
    category: 'education',
    amount: 2200.00,
    dueDate: 'Dec 23',
    status: 'due_soon',
    householdId: 'hh1',
    householdName: 'Smith Family',
    accountNumber: 'Student ID: 45892',
    autoPay: false,
    notes: 'Spring semester tuition',
  },
  {
    id: 'bill4',
    vendorName: 'Maria Santos (Nanny)',
    category: 'childcare',
    amount: 1200.00,
    dueDate: 'Dec 22',
    status: 'due_soon',
    householdId: 'hh1',
    householdName: 'Smith Family',
    autoPay: true,
  },
  {
    id: 'bill5',
    vendorName: 'Comcast Internet',
    category: 'utilities',
    amount: 189.99,
    dueDate: 'Dec 24',
    status: 'due_soon',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    accountNumber: '****7721',
    autoPay: false,
  },
  {
    id: 'bill6',
    vendorName: 'State Farm Insurance',
    category: 'insurance',
    amount: 284.00,
    dueDate: 'Dec 25',
    status: 'due_soon',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    accountNumber: 'Policy #HO-4892',
    autoPay: true,
  },
  // Scheduled
  {
    id: 'bill7',
    vendorName: 'Chase Mortgage',
    category: 'mortgage',
    amount: 3450.00,
    dueDate: 'Jan 1',
    status: 'scheduled',
    householdId: 'hh1',
    householdName: 'Smith Family',
    accountNumber: 'Loan #****9921',
    autoPay: true,
  },
  {
    id: 'bill8',
    vendorName: 'Soccer Stars Academy',
    category: 'activities',
    amount: 175.00,
    dueDate: 'Dec 28',
    status: 'scheduled',
    householdId: 'hh1',
    householdName: 'Smith Family',
    notes: "Emma's winter session",
    autoPay: false,
  },
  // Pending Approval
  {
    id: 'bill9',
    vendorName: 'Happy Paws Vet',
    category: 'pet',
    amount: 342.50,
    dueDate: 'Dec 27',
    status: 'pending_approval',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    notes: 'Annual checkup + vaccines',
    autoPay: false,
  },
  {
    id: 'bill10',
    vendorName: 'A-1 Lawn Care',
    category: 'services',
    amount: 150.00,
    dueDate: 'Dec 26',
    status: 'pending_approval',
    householdId: 'hh1',
    householdName: 'Smith Family',
    notes: 'December service',
    autoPay: false,
  },
  {
    id: 'bill11',
    vendorName: 'Kumon Learning',
    category: 'education',
    amount: 320.00,
    dueDate: 'Dec 30',
    status: 'pending_approval',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    notes: 'Math tutoring - January',
    autoPay: false,
  },
];

const mockPaymentAccounts: PaymentAccount[] = [
  { id: 'acc1', name: 'Haven Operating Account', type: 'operating', balance: 45230.00 },
  { id: 'acc2', name: 'Smith Family Float', type: 'float', balance: 8420.00 },
  { id: 'acc3', name: 'Johnson Family Float', type: 'float', balance: 3150.00 },
];

// ============================================================================
// HELPER FUNCTIONS & CONFIGS
// ============================================================================

const categoryConfig: Record<BillCategory, { label: string; icon: React.ReactNode; color: string }> = {
  mortgage: { label: 'Mortgage', icon: <Building2 className="w-5 h-5" />, color: 'text-indigo-600' },
  utilities: { label: 'Utilities', icon: <Zap className="w-5 h-5" />, color: 'text-amber-600' },
  insurance: { label: 'Insurance', icon: <Shield className="w-5 h-5" />, color: 'text-blue-600' },
  childcare: { label: 'Childcare', icon: <Heart className="w-5 h-5" />, color: 'text-pink-600' },
  education: { label: 'Education', icon: <GraduationCap className="w-5 h-5" />, color: 'text-purple-600' },
  activities: { label: 'Activities', icon: <Trophy className="w-5 h-5" />, color: 'text-orange-600' },
  pet: { label: 'Pet', icon: <Dog className="w-5 h-5" />, color: 'text-emerald-600' },
  services: { label: 'Services', icon: <Wrench className="w-5 h-5" />, color: 'text-slate-600' },
};

const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
};

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function BillPaymentCenterPage() {
  const [bills] = useState<Bill[]>(mockBills);
  const [accounts] = useState<PaymentAccount[]>(mockPaymentAccounts);
  const [viewMode, setViewMode] = useState<ViewMode>('by_due_date');
  const [selectedBills, setSelectedBills] = useState<string[]>([]);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [showLogExpenseModal, setShowLogExpenseModal] = useState(false);
  const [expandedHouseholds, setExpandedHouseholds] = useState<string[]>(['hh1', 'hh2']);
  const [selectedPaymentAccount, setSelectedPaymentAccount] = useState<string>('acc1');
  const [sendConfirmation, setSendConfirmation] = useState(false);
  const [logToRecords, setLogToRecords] = useState(true);
  const [isProcessing, setIsProcessing] = useState(false);
  const [paymentSuccess, setPaymentSuccess] = useState(false);

  // Computed values
  const overdueBills = bills.filter(b => b.status === 'overdue');
  const dueSoonBills = bills.filter(b => b.status === 'due_soon');
  const pendingApprovalBills = bills.filter(b => b.status === 'pending_approval');
  const allUnpaidBills = bills.filter(b => b.status !== 'paid');

  const overdueTotal = overdueBills.reduce((sum, b) => sum + b.amount, 0);
  const dueThisWeekTotal = dueSoonBills.reduce((sum, b) => sum + b.amount, 0);
  const selectedTotal = selectedBills.reduce((sum, id) => {
    const bill = bills.find(b => b.id === id);
    return sum + (bill?.amount || 0);
  }, 0);

  // Group by household
  const billsByHousehold = allUnpaidBills.reduce((acc, bill) => {
    if (!acc[bill.householdId]) {
      acc[bill.householdId] = { name: bill.householdName, bills: [] };
    }
    acc[bill.householdId]!.bills.push(bill);
    return acc;
  }, {} as Record<string, { name: string; bills: Bill[] }>);

  const toggleBillSelection = (billId: string) => {
    setSelectedBills(prev =>
      prev.includes(billId)
        ? prev.filter(id => id !== billId)
        : [...prev, billId]
    );
  };

  const selectAllInSection = (billIds: string[]) => {
    const allSelected = billIds.every(id => selectedBills.includes(id));
    if (allSelected) {
      setSelectedBills(prev => prev.filter(id => !billIds.includes(id)));
    } else {
      setSelectedBills(prev => [...new Set([...prev, ...billIds])]);
    }
  };

  const toggleHouseholdExpanded = (householdId: string) => {
    setExpandedHouseholds(prev =>
      prev.includes(householdId)
        ? prev.filter(id => id !== householdId)
        : [...prev, householdId]
    );
  };

  const handleStartPayment = () => {
    if (selectedBills.length > 0) {
      setShowPaymentModal(true);
    }
  };

  const handleProcessPayment = async () => {
    setIsProcessing(true);
    // Simulate payment processing
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsProcessing(false);
    setPaymentSuccess(true);
  };

  const handleClosePaymentModal = () => {
    setShowPaymentModal(false);
    setPaymentSuccess(false);
    if (paymentSuccess) {
      setSelectedBills([]);
    }
  };

  // Get selected bills grouped by household
  const selectedBillsData = selectedBills.map(id => bills.find(b => b.id === id)!).filter(Boolean);
  const selectedByHousehold = selectedBillsData.reduce((acc, bill) => {
    if (!acc[bill.householdId]) {
      acc[bill.householdId] = { name: bill.householdName, bills: [], total: 0 };
    }
    acc[bill.householdId]!.bills.push(bill);
    acc[bill.householdId]!.total += bill.amount;
    return acc;
  }, {} as Record<string, { name: string; bills: Bill[]; total: number }>);

  // Bill Row Component
  const BillRow = ({ bill, showHousehold = true }: { bill: Bill; showHousehold?: boolean }) => {
    const category = categoryConfig[bill.category];
    const isSelected = selectedBills.includes(bill.id);

    return (
      <div
        className={`p-4 rounded-lg border transition-all ${
          isSelected
            ? 'bg-indigo-50 border-indigo-300'
            : 'bg-white border-slate-200 hover:border-slate-300'
        }`}
      >
        <div className="flex items-start gap-4">
          {/* Checkbox */}
          <input
            type="checkbox"
            checked={isSelected}
            onChange={() => toggleBillSelection(bill.id)}
            className="mt-1 w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
          />

          {/* Category Icon */}
          <div className={`flex-shrink-0 ${category.color}`}>
            {category.icon}
          </div>

          {/* Main Content */}
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h4 className="font-medium text-slate-900">{bill.vendorName}</h4>
                <div className="flex items-center gap-2 mt-1 text-sm text-slate-500">
                  {showHousehold && (
                    <>
                      <span>{bill.householdName}</span>
                      <span>•</span>
                    </>
                  )}
                  {bill.accountNumber && (
                    <>
                      <span>Account: {bill.accountNumber}</span>
                      <span>•</span>
                    </>
                  )}
                  <span className={bill.autoPay ? 'text-emerald-600' : 'text-slate-400'}>
                    Auto-pay: {bill.autoPay ? 'ON' : 'OFF'}
                  </span>
                </div>
                {bill.notes && (
                  <p className="text-sm text-slate-500 mt-1 italic">{bill.notes}</p>
                )}
              </div>

              <div className="text-right flex-shrink-0">
                <p className="font-semibold text-slate-900">{formatCurrency(bill.amount)}</p>
                <p className={`text-sm ${bill.status === 'overdue' ? 'text-red-600 font-medium' : 'text-slate-500'}`}>
                  Due: {bill.dueDate}
                </p>
              </div>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-2 mt-3">
              <button className="px-3 py-1.5 text-sm font-medium text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors">
                Pay Now
              </button>
              <button className="px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                Schedule
              </button>
              {bill.billUrl && (
                <button className="px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors flex items-center gap-1">
                  <ExternalLink className="w-3.5 h-3.5" />
                  View Bill
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6 pb-24">
      {/* Header */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div className="flex items-center gap-3 mb-6">
          <div className="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center">
            <CreditCard className="w-6 h-6 text-indigo-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-slate-900">Bill Payment Center</h1>
            <p className="text-slate-500">Manage and pay bills on behalf of households</p>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <div className="bg-amber-50 rounded-xl p-4 border border-amber-100">
            <p className="text-2xl font-bold text-slate-900">{formatCurrency(dueThisWeekTotal)}</p>
            <p className="text-sm text-slate-600">Due This Week</p>
          </div>
          <div className="bg-red-50 rounded-xl p-4 border border-red-100">
            <div className="flex items-center gap-2">
              <p className="text-2xl font-bold text-slate-900">{formatCurrency(overdueTotal)}</p>
              <span className="w-2.5 h-2.5 bg-red-500 rounded-full animate-pulse" />
            </div>
            <p className="text-sm text-slate-600">Overdue</p>
          </div>
          <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
            <p className="text-2xl font-bold text-slate-900">{allUnpaidBills.length}</p>
            <p className="text-sm text-slate-600">Bills to Pay</p>
          </div>
          <div className="bg-purple-50 rounded-xl p-4 border border-purple-100">
            <p className="text-2xl font-bold text-slate-900">{pendingApprovalBills.length}</p>
            <p className="text-sm text-slate-600">Pending Approval</p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-wrap gap-3">
          <button
            onClick={handleStartPayment}
            disabled={selectedBills.length === 0}
            className="inline-flex items-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <CreditCard className="w-5 h-5" />
            Start Payment Session
          </button>
          <button className="inline-flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 text-slate-700 rounded-lg font-medium hover:bg-slate-50 transition-colors">
            <BarChart3 className="w-5 h-5" />
            Payment Report
          </button>
          <button className="inline-flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 text-slate-700 rounded-lg font-medium hover:bg-slate-50 transition-colors">
            <Settings className="w-5 h-5" />
            Auto-Pay Settings
          </button>
          <button
            onClick={() => setShowLogExpenseModal(true)}
            className="inline-flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 text-slate-700 rounded-lg font-medium hover:bg-slate-50 transition-colors"
          >
            <Plus className="w-5 h-5" />
            Log Expense
          </button>
        </div>
      </div>

      {/* View Toggles */}
      <div className="flex gap-2 bg-white rounded-lg p-1 shadow-sm border border-slate-200 w-fit">
        <button
          onClick={() => setViewMode('by_due_date')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            viewMode === 'by_due_date'
              ? 'bg-indigo-600 text-white'
              : 'text-slate-600 hover:bg-slate-100'
          }`}
        >
          By Due Date
        </button>
        <button
          onClick={() => setViewMode('by_household')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            viewMode === 'by_household'
              ? 'bg-indigo-600 text-white'
              : 'text-slate-600 hover:bg-slate-100'
          }`}
        >
          By Household
        </button>
        <button
          onClick={() => setViewMode('all')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            viewMode === 'all'
              ? 'bg-indigo-600 text-white'
              : 'text-slate-600 hover:bg-slate-100'
          }`}
        >
          All Bills
        </button>
      </div>

      {/* Bills List */}
      {viewMode === 'by_due_date' && (
        <div className="space-y-6">
          {/* Overdue Section */}
          {overdueBills.length > 0 && (
            <div className="bg-red-50 rounded-xl border border-red-200 p-4">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5 text-red-600" />
                  <h3 className="font-semibold text-red-800">OVERDUE</h3>
                  <span className="text-sm text-red-600">({overdueBills.length} bills)</span>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-lg font-bold text-red-700">{formatCurrency(overdueTotal)}</span>
                  <button
                    onClick={() => selectAllInSection(overdueBills.map(b => b.id))}
                    className="text-sm text-red-600 hover:text-red-800 font-medium"
                  >
                    {overdueBills.every(b => selectedBills.includes(b.id)) ? 'Deselect All' : 'Select All'}
                  </button>
                </div>
              </div>
              <div className="space-y-3">
                {overdueBills.map(bill => (
                  <BillRow key={bill.id} bill={bill} />
                ))}
              </div>
            </div>
          )}

          {/* Due This Week Section */}
          {dueSoonBills.length > 0 && (
            <div className="bg-amber-50 rounded-xl border border-amber-200 p-4">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <Clock className="w-5 h-5 text-amber-600" />
                  <h3 className="font-semibold text-amber-800">DUE THIS WEEK</h3>
                  <span className="text-sm text-amber-600">({dueSoonBills.length} bills)</span>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-lg font-bold text-amber-700">{formatCurrency(dueThisWeekTotal)}</span>
                  <button
                    onClick={() => selectAllInSection(dueSoonBills.map(b => b.id))}
                    className="text-sm text-amber-600 hover:text-amber-800 font-medium"
                  >
                    {dueSoonBills.every(b => selectedBills.includes(b.id)) ? 'Deselect All' : 'Select All'}
                  </button>
                </div>
              </div>
              <div className="space-y-3">
                {dueSoonBills.map(bill => (
                  <BillRow key={bill.id} bill={bill} />
                ))}
              </div>
            </div>
          )}

          {/* Pending Approval Section */}
          {pendingApprovalBills.length > 0 && (
            <div className="bg-purple-50 rounded-xl border border-purple-200 p-4">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <FileText className="w-5 h-5 text-purple-600" />
                  <h3 className="font-semibold text-purple-800">PENDING APPROVAL</h3>
                  <span className="text-sm text-purple-600">({pendingApprovalBills.length} bills)</span>
                </div>
                <span className="text-lg font-bold text-purple-700">
                  {formatCurrency(pendingApprovalBills.reduce((sum, b) => sum + b.amount, 0))}
                </span>
              </div>
              <div className="space-y-3">
                {pendingApprovalBills.map(bill => (
                  <BillRow key={bill.id} bill={bill} />
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {viewMode === 'by_household' && (
        <div className="space-y-4">
          {Object.entries(billsByHousehold).map(([householdId, { name, bills: householdBills }]) => {
            const isExpanded = expandedHouseholds.includes(householdId);
            const householdTotal = householdBills.reduce((sum, b) => sum + b.amount, 0);

            return (
              <div key={householdId} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                <button
                  onClick={() => toggleHouseholdExpanded(householdId)}
                  className="w-full px-4 py-3 flex items-center justify-between hover:bg-slate-50 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    {isExpanded ? (
                      <ChevronDown className="w-5 h-5 text-slate-400" />
                    ) : (
                      <ChevronRight className="w-5 h-5 text-slate-400" />
                    )}
                    <h3 className="font-semibold text-slate-900">{name}</h3>
                    <span className="text-sm text-slate-500">({householdBills.length} bills)</span>
                  </div>
                  <div className="flex items-center gap-4">
                    <span className="font-semibold text-slate-900">{formatCurrency(householdTotal)}</span>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        selectAllInSection(householdBills.map(b => b.id));
                      }}
                      className="text-sm text-indigo-600 hover:text-indigo-800 font-medium"
                    >
                      {householdBills.every(b => selectedBills.includes(b.id)) ? 'Deselect' : 'Select All'}
                    </button>
                  </div>
                </button>

                {isExpanded && (
                  <div className="px-4 pb-4 space-y-3">
                    {householdBills.map(bill => (
                      <BillRow key={bill.id} bill={bill} showHousehold={false} />
                    ))}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {viewMode === 'all' && (
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 space-y-3">
          {allUnpaidBills.map(bill => (
            <BillRow key={bill.id} bill={bill} />
          ))}
        </div>
      )}

      {/* Batch Selection Bar */}
      {selectedBills.length > 0 && (
        <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 shadow-lg p-4 z-40">
          <div className="max-w-6xl mx-auto flex items-center justify-between">
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                checked={true}
                readOnly
                className="w-5 h-5 rounded border-slate-300 text-indigo-600"
              />
              <span className="font-medium text-slate-900">
                {selectedBills.length} bill{selectedBills.length > 1 ? 's' : ''} selected
              </span>
              <span className="text-slate-500">({formatCurrency(selectedTotal)})</span>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setSelectedBills([])}
                className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium transition-colors"
              >
                Clear
              </button>
              <button
                onClick={handleStartPayment}
                className="px-6 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition-colors flex items-center gap-2"
              >
                Pay Selected
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Payment Session Modal */}
      {showPaymentModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-hidden">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <CreditCard className="w-6 h-6 text-indigo-600" />
                <h2 className="text-xl font-semibold text-slate-900">Payment Session</h2>
              </div>
              <button
                onClick={handleClosePaymentModal}
                className="p-2 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto max-h-[60vh]">
              {paymentSuccess ? (
                /* Success State */
                <div className="text-center py-8">
                  <div className="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <CheckCircle2 className="w-8 h-8 text-emerald-600" />
                  </div>
                  <h3 className="text-xl font-semibold text-slate-900 mb-2">Payment Successful!</h3>
                  <p className="text-slate-500 mb-6">
                    {selectedBills.length} bill{selectedBills.length > 1 ? 's' : ''} paid totaling {formatCurrency(selectedTotal)}
                  </p>
                  <div className="bg-slate-50 rounded-lg p-4 mb-6 text-left">
                    <p className="text-sm text-slate-600 mb-2">
                      <span className="font-medium">Transaction ID:</span> TXN-2024122101-{Math.random().toString(36).substring(7).toUpperCase()}
                    </p>
                    <p className="text-sm text-slate-600">
                      <span className="font-medium">Confirmation:</span> Sent to household accounts
                    </p>
                  </div>
                </div>
              ) : (
                /* Payment Preview */
                <>
                  <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-4">
                    Selected for Payment
                  </h3>

                  {/* Bills by Household */}
                  <div className="space-y-6 mb-6">
                    {Object.entries(selectedByHousehold).map(([householdId, { name, bills: hBills, total }]) => (
                      <div key={householdId}>
                        <div className="flex items-center justify-between mb-3">
                          <h4 className="font-semibold text-slate-900">{name}</h4>
                          <span className="text-sm font-medium text-slate-500">Subtotal: {formatCurrency(total)}</span>
                        </div>
                        <div className="space-y-2 pl-4 border-l-2 border-slate-200">
                          {hBills.map(bill => {
                            const category = categoryConfig[bill.category];
                            return (
                              <div key={bill.id} className="flex items-center justify-between py-2">
                                <div className="flex items-center gap-3">
                                  <span className={category.color}>{category.icon}</span>
                                  <span className="text-slate-700">{bill.vendorName}</span>
                                </div>
                                <span className="font-medium text-slate-900">{formatCurrency(bill.amount)}</span>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    ))}
                  </div>

                  {/* Total */}
                  <div className="border-t border-slate-200 pt-4 mb-6">
                    <div className="flex items-center justify-between">
                      <span className="text-lg font-semibold text-slate-900">TOTAL</span>
                      <span className="text-2xl font-bold text-slate-900">{formatCurrency(selectedTotal)}</span>
                    </div>
                  </div>

                  {/* Payment Method */}
                  <div className="mb-6">
                    <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3">
                      Payment Method
                    </h3>
                    <div className="space-y-2">
                      {accounts.map(account => (
                        <label
                          key={account.id}
                          className={`flex items-center justify-between p-3 rounded-lg border cursor-pointer transition-colors ${
                            selectedPaymentAccount === account.id
                              ? 'border-indigo-500 bg-indigo-50'
                              : 'border-slate-200 hover:border-slate-300'
                          }`}
                        >
                          <div className="flex items-center gap-3">
                            <input
                              type="radio"
                              name="paymentAccount"
                              value={account.id}
                              checked={selectedPaymentAccount === account.id}
                              onChange={() => setSelectedPaymentAccount(account.id)}
                              className="w-4 h-4 text-indigo-600 focus:ring-indigo-500"
                            />
                            <span className="font-medium text-slate-900">{account.name}</span>
                          </div>
                          <span className="text-slate-600">Balance: {formatCurrency(account.balance)}</span>
                        </label>
                      ))}
                    </div>
                  </div>

                  {/* Options */}
                  <div className="space-y-3">
                    <label className="flex items-center gap-3 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={sendConfirmation}
                        onChange={(e) => setSendConfirmation(e.target.checked)}
                        className="w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                      />
                      <span className="text-slate-700">Send confirmation to homeowners</span>
                    </label>
                    <label className="flex items-center gap-3 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={logToRecords}
                        onChange={(e) => setLogToRecords(e.target.checked)}
                        className="w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                      />
                      <span className="text-slate-700">Log to household expense records</span>
                    </label>
                  </div>
                </>
              )}
            </div>

            {/* Modal Footer */}
            <div className="px-6 py-4 border-t border-slate-200 flex justify-end gap-3">
              {paymentSuccess ? (
                <>
                  <button
                    onClick={handleClosePaymentModal}
                    className="px-6 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition-colors"
                  >
                    Done
                  </button>
                  <button className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium transition-colors">
                    View Report
                  </button>
                </>
              ) : (
                <>
                  <button
                    onClick={handleClosePaymentModal}
                    className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleProcessPayment}
                    disabled={isProcessing}
                    className="px-6 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                  >
                    {isProcessing ? (
                      <>
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                        Processing...
                      </>
                    ) : (
                      <>
                        Process Payment
                        <ChevronRight className="w-5 h-5" />
                      </>
                    )}
                  </button>
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Log Expense Modal */}
      {showLogExpenseModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-lg w-full max-h-[90vh] overflow-hidden">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Plus className="w-6 h-6 text-indigo-600" />
                <h2 className="text-xl font-semibold text-slate-900">Log Expense</h2>
              </div>
              <button
                onClick={() => setShowLogExpenseModal(false)}
                className="p-2 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 space-y-4">
              {/* Household */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Household</label>
                <select className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500">
                  <option>Select household...</option>
                  <option>Smith Family</option>
                  <option>Johnson Family</option>
                </select>
              </div>

              {/* Amount & Date */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Amount</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500">$</span>
                    <input
                      type="number"
                      step="0.01"
                      placeholder="0.00"
                      className="w-full pl-8 pr-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Date</label>
                  <div className="relative">
                    <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <input
                      type="date"
                      className="w-full pl-10 pr-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                  </div>
                </div>
              </div>

              {/* Category */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
                <select className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500">
                  <option>Select category...</option>
                  <option>Services</option>
                  <option>Utilities</option>
                  <option>Supplies</option>
                  <option>Repairs</option>
                  <option>Other</option>
                </select>
              </div>

              {/* Vendor/Payee */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Vendor/Payee</label>
                <input
                  type="text"
                  placeholder="Enter vendor name"
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                />
              </div>

              {/* Description */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Description</label>
                <textarea
                  rows={2}
                  placeholder="Enter description..."
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 resize-none"
                />
              </div>

              {/* Link to Work Order */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Link to Work Order (optional)</label>
                <div className="relative">
                  <Link2 className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                  <select className="w-full pl-10 pr-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500">
                    <option>None</option>
                    <option>WO-1892 - HVAC Service</option>
                    <option>WO-1891 - Kitchen Faucet</option>
                  </select>
                </div>
              </div>

              {/* Receipt Upload */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Receipt (optional)</label>
                <div className="border-2 border-dashed border-slate-300 rounded-lg p-4 text-center hover:border-indigo-400 transition-colors cursor-pointer">
                  <Upload className="w-6 h-6 text-slate-400 mx-auto mb-2" />
                  <p className="text-sm text-slate-600">Click to upload or drag and drop</p>
                  <p className="text-xs text-slate-400">PNG, JPG, PDF up to 10MB</p>
                </div>
              </div>

              {/* Add to Statement */}
              <label className="flex items-center gap-3 cursor-pointer pt-2">
                <input
                  type="checkbox"
                  defaultChecked
                  className="w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                />
                <span className="text-slate-700">Add to household statement</span>
              </label>
            </div>

            {/* Modal Footer */}
            <div className="px-6 py-4 border-t border-slate-200 flex justify-end gap-3">
              <button
                onClick={() => setShowLogExpenseModal(false)}
                className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium transition-colors"
              >
                Cancel
              </button>
              <button className="px-6 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition-colors flex items-center gap-2">
                <Send className="w-4 h-4" />
                Log Expense
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
