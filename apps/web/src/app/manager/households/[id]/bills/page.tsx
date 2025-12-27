'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Plus,
  ChevronDown,
  ChevronRight,
  Loader2,
  DollarSign,
  Home,
  Zap,
  Wifi,
  Car,
  CreditCard,
  Users,
  Shield,
  Wrench,
  Tv,
  MoreHorizontal,
  Check,
  X,
  ExternalLink,
  Calendar,
  Building2,
  Phone,
  Edit2,
  Trash2,
  Calculator,
} from 'lucide-react';
import { getIdToken } from '@/lib/firebase';

// ===========================================================================
// TYPES
// ===========================================================================

interface Bill {
  id: string;
  category: string;
  name: string;
  payeeName?: string;
  accountNumber?: string;
  amount: number;
  frequency: string;
  monthlyAmount?: number;
  dueDay?: number;
  paymentMethod?: string;
  havenManaged: boolean;
  status: string;
  portalUrl?: string;
  notes?: string;
}

interface BillSection {
  id: string;
  title: string;
  description: string;
  icon: string;
  bills: BillTemplate[];
}

interface BillTemplate {
  id: string;
  billCategory: string;
  label: string;
  description?: string;
  icon?: string;
  fields: FieldConfig[];
}

interface FieldConfig {
  id: string;
  label: string;
  inputType: string;
  required: boolean;
  options?: string[];
  placeholder?: string;
  helpText?: string;
}

interface BillSummary {
  summary: Record<string, {
    count: number;
    monthlyTotal: number;
    bills: Bill[];
  }>;
  totalBills: number;
  totalMonthly: number;
  havenManagedTotal: number;
  havenServiceFee: number;
  recommendedBuffer: number;
  recommendedMonthlyFunding: number;
}

// ===========================================================================
// CATEGORY ICONS AND COLORS
// ===========================================================================

const CATEGORY_CONFIG: Record<string, { icon: React.ComponentType<any>; color: string; label: string }> = {
  housing: { icon: Home, color: 'bg-blue-100 text-blue-600', label: 'Housing' },
  utilities: { icon: Zap, color: 'bg-amber-100 text-amber-600', label: 'Utilities' },
  telecom: { icon: Wifi, color: 'bg-purple-100 text-purple-600', label: 'Internet & Phone' },
  vehicles: { icon: Car, color: 'bg-green-100 text-green-600', label: 'Vehicles' },
  loans: { icon: CreditCard, color: 'bg-red-100 text-red-600', label: 'Loans & Debt' },
  family: { icon: Users, color: 'bg-pink-100 text-pink-600', label: 'Family & Children' },
  insurance: { icon: Shield, color: 'bg-indigo-100 text-indigo-600', label: 'Insurance' },
  homeServices: { icon: Wrench, color: 'bg-orange-100 text-orange-600', label: 'Home Services' },
  memberships: { icon: Tv, color: 'bg-cyan-100 text-cyan-600', label: 'Memberships' },
  other: { icon: MoreHorizontal, color: 'bg-gray-100 text-gray-600', label: 'Other' },
};

// ===========================================================================
// MAIN COMPONENT
// ===========================================================================

export default function HouseholdBillsPage() {
  const params = useParams();
  const router = useRouter();
  const householdId = params.id as string;

  const [isLoading, setIsLoading] = useState(true);
  const [billSections, setBillSections] = useState<BillSection[]>([]);
  const [existingBills, setExistingBills] = useState<Bill[]>([]);
  const [billSummary, setBillSummary] = useState<BillSummary | null>(null);
  const [expandedSection, setExpandedSection] = useState<string | null>(null);
  const [showAddBill, setShowAddBill] = useState(false);
  const [selectedBillTemplate, setSelectedBillTemplate] = useState<BillTemplate | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [showFundingCalc, setShowFundingCalc] = useState(false);

  // Form state
  const [billFormData, setBillFormData] = useState<Record<string, any>>({});

  useEffect(() => {
    fetchData();
  }, [householdId]);

  const fetchData = async () => {
    setIsLoading(true);
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      // Fetch bill sections
      const sectionsRes = await fetch(`${apiUrl}/intake/household/${householdId}/bill-sections`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (sectionsRes.ok) {
        const data = await sectionsRes.json();
        setBillSections(data.sections || []);
      }

      // Fetch existing bills
      const billsRes = await fetch(`${apiUrl}/intake/household/${householdId}/bills`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (billsRes.ok) {
        const bills = await billsRes.json();
        setExistingBills(bills);
      }

      // Fetch bill summary
      const summaryRes = await fetch(`${apiUrl}/intake/household/${householdId}/bills/summary`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (summaryRes.ok) {
        const summary = await summaryRes.json();
        setBillSummary(summary);
      }
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleAddBill = async () => {
    if (!selectedBillTemplate) return;
    setIsSaving(true);

    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const res = await fetch(`${apiUrl}/intake/household/${householdId}/bills`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          category: selectedBillTemplate.billCategory,
          name: billFormData.payee_name || selectedBillTemplate.label,
          payeeName: billFormData.payee_name,
          accountNumber: billFormData.account_number,
          amount: parseFloat(billFormData.amount) || 0,
          frequency: billFormData.frequency || 'Monthly',
          dueDay: billFormData.due_day ? parseInt(billFormData.due_day) : undefined,
          amountType: billFormData.amount_type,
          paymentMethod: billFormData.payment_method || 'Haven Pays',
          currentAutopay: billFormData.current_autopay === 'true',
          portalUrl: billFormData.portal_url,
          portalUsername: billFormData.portal_username,
          portalNotes: billFormData.portal_notes,
          notes: billFormData.notes,
          // Loan fields
          principalBalance: billFormData.principal_balance ? parseFloat(billFormData.principal_balance) : undefined,
          interestRate: billFormData.interest_rate ? parseFloat(billFormData.interest_rate) : undefined,
          loanTerm: billFormData.loan_term,
          maturityDate: billFormData.maturity_date,
          escrowIncluded: billFormData.escrow_included === 'true',
          // Insurance fields
          policyNumber: billFormData.policy_number,
          coverageAmount: billFormData.coverage_amount ? parseFloat(billFormData.coverage_amount) : undefined,
          deductible: billFormData.deductible ? parseFloat(billFormData.deductible) : undefined,
          renewalDate: billFormData.renewal_date,
        }),
      });

      if (res.ok) {
        const newBill = await res.json();
        setExistingBills([...existingBills, newBill]);
        setShowAddBill(false);
        setSelectedBillTemplate(null);
        setBillFormData({});
        // Refresh summary
        fetchData();
      }
    } catch (error) {
      console.error('Error adding bill:', error);
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteBill = async (billId: string) => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const res = await fetch(`${apiUrl}/intake/household/${householdId}/bills/${billId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });

      if (res.ok) {
        setExistingBills(existingBills.filter(b => b.id !== billId));
        fetchData();
      }
    } catch (error) {
      console.error('Error deleting bill:', error);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const getBillsForCategory = (categoryKey: string) => {
    const categoryMap: Record<string, string[]> = {
      housing: ['MORTGAGE', 'RENT', 'PROPERTY_TAX', 'HOA', 'HOME_INSURANCE'],
      utilities: ['ELECTRIC', 'GAS', 'WATER_SEWER', 'OIL_PROPANE', 'TRASH'],
      telecom: ['INTERNET', 'CABLE_TV', 'CELL_PHONE', 'LANDLINE'],
      vehicles: ['CAR_PAYMENT', 'AUTO_INSURANCE', 'CAR_REGISTRATION', 'PARKING', 'TOLLS'],
      loans: ['STUDENT_LOAN', 'PERSONAL_LOAN', 'HELOC', 'CREDIT_CARD'],
      family: ['SCHOOL_TUITION', 'CHILDCARE', 'NANNY', 'KIDS_ACTIVITY', 'SCHOOL_LUNCH', 'TUTORING'],
      insurance: ['LIFE_INSURANCE', 'HEALTH_INSURANCE', 'UMBRELLA_INSURANCE', 'PET_INSURANCE', 'DISABILITY_INSURANCE', 'LONG_TERM_CARE'],
      homeServices: ['LAWN_LANDSCAPE', 'POOL_SERVICE', 'PEST_CONTROL', 'SECURITY_MONITORING', 'HOUSE_CLEANING', 'SNOW_REMOVAL'],
      memberships: ['GYM_FITNESS', 'CLUB_MEMBERSHIP', 'STREAMING_SERVICE', 'SOFTWARE_SUBSCRIPTION', 'NEWSPAPER_MAGAZINE', 'MEAL_KIT', 'AMAZON_PRIME', 'WAREHOUSE_CLUB'],
      other: ['STORAGE', 'PET_CARE', 'CHARITY_DONATION', 'CHILD_SUPPORT', 'ALIMONY', 'OTHER_BILL'],
    };
    const categories = categoryMap[categoryKey] || [];
    return existingBills.filter(b => categories.includes(b.category));
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-haven-champagne-600 mx-auto mb-4" />
          <p className="text-gray-500">Loading bills...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-20">
        <div className="max-w-6xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => router.push(`/manager/households/${householdId}/profile`)}
                className="p-2 hover:bg-gray-100 rounded-lg transition"
              >
                <ArrowLeft className="w-5 h-5 text-gray-600" />
              </button>
              <div>
                <h1 className="text-lg font-bold text-haven-navy-900">
                  Bills & Payments
                </h1>
                <p className="text-sm text-gray-500">
                  Capture all recurring payments for one-bill management
                </p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setShowFundingCalc(true)}
                className="flex items-center gap-2 px-4 py-2 bg-haven-champagne-100 text-haven-champagne-700 rounded-lg text-sm font-medium hover:bg-haven-champagne-200 transition"
              >
                <Calculator className="w-4 h-4" />
                Monthly Funding
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 py-6">
        <div className="grid grid-cols-12 gap-6">
          {/* Left Column - Bill Categories */}
          <div className="col-span-8">
            <div className="space-y-4">
              {Object.entries(CATEGORY_CONFIG).map(([key, config]) => {
                const Icon = config.icon;
                const categoryBills = getBillsForCategory(key);
                const section = billSections.find(s => s.id === `bills_${key}` || s.id.includes(key));
                const isExpanded = expandedSection === key;
                const monthlyTotal = categoryBills.reduce((sum, b) => sum + (b.monthlyAmount || b.amount), 0);

                return (
                  <div key={key} className="bg-white rounded-xl border border-gray-200 overflow-hidden">
                    {/* Category Header */}
                    <button
                      onClick={() => setExpandedSection(isExpanded ? null : key)}
                      className="w-full p-4 flex items-center justify-between hover:bg-gray-50 transition"
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${config.color}`}>
                          <Icon className="w-5 h-5" />
                        </div>
                        <div className="text-left">
                          <p className="font-semibold text-haven-navy-900">{config.label}</p>
                          <p className="text-sm text-gray-500">
                            {categoryBills.length} bills • {formatCurrency(monthlyTotal)}/mo
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        {categoryBills.length > 0 && (
                          <span className="px-2 py-1 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                            {categoryBills.length} captured
                          </span>
                        )}
                        {isExpanded ? (
                          <ChevronDown className="w-5 h-5 text-gray-400" />
                        ) : (
                          <ChevronRight className="w-5 h-5 text-gray-400" />
                        )}
                      </div>
                    </button>

                    {/* Expanded Content */}
                    {isExpanded && (
                      <div className="border-t border-gray-100">
                        {/* Existing Bills */}
                        {categoryBills.length > 0 && (
                          <div className="p-4 space-y-3">
                            {categoryBills.map((bill) => (
                              <div
                                key={bill.id}
                                className="p-4 border border-gray-200 rounded-xl flex items-center justify-between"
                              >
                                <div className="flex items-center gap-3">
                                  <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
                                    <DollarSign className="w-5 h-5 text-gray-600" />
                                  </div>
                                  <div>
                                    <p className="font-medium text-haven-navy-900">
                                      {bill.payeeName || bill.name}
                                    </p>
                                    <p className="text-sm text-gray-500">
                                      {formatCurrency(bill.amount)} / {bill.frequency}
                                      {bill.accountNumber && ` • Acct: ...${bill.accountNumber.slice(-4)}`}
                                    </p>
                                  </div>
                                </div>
                                <div className="flex items-center gap-2">
                                  {bill.havenManaged && (
                                    <span className="px-2 py-1 bg-haven-champagne-100 text-haven-champagne-700 text-xs font-medium rounded-full">
                                      Haven Pays
                                    </span>
                                  )}
                                  {bill.portalUrl && (
                                    <a
                                      href={bill.portalUrl}
                                      target="_blank"
                                      rel="noopener noreferrer"
                                      className="p-1.5 hover:bg-gray-100 rounded transition"
                                    >
                                      <ExternalLink className="w-4 h-4 text-gray-400" />
                                    </a>
                                  )}
                                  <button
                                    onClick={() => handleDeleteBill(bill.id)}
                                    className="p-1.5 hover:bg-red-50 rounded transition text-gray-400 hover:text-red-500"
                                  >
                                    <Trash2 className="w-4 h-4" />
                                  </button>
                                </div>
                              </div>
                            ))}
                          </div>
                        )}

                        {/* Add Bill Options */}
                        <div className="p-4 bg-gray-50 border-t border-gray-100">
                          <p className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-3">
                            Add {config.label} Bill
                          </p>
                          <div className="flex flex-wrap gap-2">
                            {section?.bills?.slice(0, 8).map((billTemplate) => (
                              <button
                                key={billTemplate.id}
                                onClick={() => {
                                  setSelectedBillTemplate(billTemplate);
                                  setBillFormData({});
                                  setShowAddBill(true);
                                }}
                                className="px-3 py-1.5 bg-white border border-gray-200 rounded-full text-sm font-medium text-gray-700 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 transition"
                              >
                                + {billTemplate.label}
                              </button>
                            ))}
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Right Column - Summary */}
          <div className="col-span-4">
            <div className="sticky top-24 space-y-4">
              {/* Monthly Summary Card */}
              <div className="bg-white rounded-xl border border-gray-200 p-6">
                <h3 className="font-semibold text-haven-navy-900 mb-4">Monthly Summary</h3>

                <div className="space-y-3">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Total Bills</span>
                    <span className="font-medium">{existingBills.length}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Monthly Total</span>
                    <span className="font-medium">{formatCurrency(billSummary?.totalMonthly || 0)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Haven Managed</span>
                    <span className="font-medium text-haven-champagne-600">
                      {formatCurrency(billSummary?.havenManagedTotal || 0)}
                    </span>
                  </div>

                  <div className="pt-3 border-t border-gray-100">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">Service Fee (3%)</span>
                      <span className="font-medium">{formatCurrency(billSummary?.havenServiceFee || 0)}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">Buffer (10%)</span>
                      <span className="font-medium">{formatCurrency(billSummary?.recommendedBuffer || 0)}</span>
                    </div>
                  </div>

                  <div className="pt-3 border-t border-gray-100">
                    <div className="flex justify-between">
                      <span className="font-semibold text-haven-navy-900">Monthly Funding</span>
                      <span className="font-bold text-lg text-haven-champagne-600">
                        {formatCurrency(billSummary?.recommendedMonthlyFunding || 0)}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Quick Stats */}
              <div className="bg-white rounded-xl border border-gray-200 p-6">
                <h3 className="font-semibold text-haven-navy-900 mb-4">Coverage</h3>
                <div className="space-y-3">
                  {Object.entries(CATEGORY_CONFIG).map(([key, config]) => {
                    const count = getBillsForCategory(key).length;
                    return (
                      <div key={key} className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">{config.label}</span>
                        <span className={`text-sm font-medium ${count > 0 ? 'text-emerald-600' : 'text-gray-400'}`}>
                          {count > 0 ? `${count} bills` : 'Not set'}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Add Bill Modal */}
      {showAddBill && selectedBillTemplate && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-100 sticky top-0 bg-white">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-haven-navy-900">
                    Add {selectedBillTemplate.label}
                  </h2>
                  {selectedBillTemplate.description && (
                    <p className="text-sm text-gray-500 mt-1">{selectedBillTemplate.description}</p>
                  )}
                </div>
                <button
                  onClick={() => {
                    setShowAddBill(false);
                    setSelectedBillTemplate(null);
                    setBillFormData({});
                  }}
                  className="p-2 hover:bg-gray-100 rounded-lg transition"
                >
                  <X className="w-5 h-5 text-gray-500" />
                </button>
              </div>
            </div>

            <div className="p-6 space-y-4">
              {selectedBillTemplate.fields.map((field) => (
                <div key={field.id}>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    {field.label}
                    {field.required && <span className="text-red-500 ml-1">*</span>}
                  </label>

                  {field.inputType === 'select' && field.options ? (
                    <select
                      value={billFormData[field.id] || ''}
                      onChange={(e) => setBillFormData({ ...billFormData, [field.id]: e.target.value })}
                      className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                    >
                      <option value="">Select...</option>
                      {field.options.map((opt) => (
                        <option key={opt} value={opt}>{opt}</option>
                      ))}
                    </select>
                  ) : field.inputType === 'boolean' ? (
                    <select
                      value={billFormData[field.id] || 'false'}
                      onChange={(e) => setBillFormData({ ...billFormData, [field.id]: e.target.value })}
                      className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                    >
                      <option value="false">No</option>
                      <option value="true">Yes</option>
                    </select>
                  ) : field.inputType === 'currency' ? (
                    <div className="relative">
                      <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500">$</span>
                      <input
                        type="number"
                        step="0.01"
                        value={billFormData[field.id] || ''}
                        onChange={(e) => setBillFormData({ ...billFormData, [field.id]: e.target.value })}
                        placeholder={field.placeholder || '0.00'}
                        className="w-full pl-8 pr-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                      />
                    </div>
                  ) : field.inputType === 'date' ? (
                    <input
                      type="date"
                      value={billFormData[field.id] || ''}
                      onChange={(e) => setBillFormData({ ...billFormData, [field.id]: e.target.value })}
                      className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                    />
                  ) : field.inputType === 'url' ? (
                    <input
                      type="url"
                      value={billFormData[field.id] || ''}
                      onChange={(e) => setBillFormData({ ...billFormData, [field.id]: e.target.value })}
                      placeholder={field.placeholder || 'https://...'}
                      className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                    />
                  ) : field.inputType === 'number' ? (
                    <input
                      type="number"
                      value={billFormData[field.id] || ''}
                      onChange={(e) => setBillFormData({ ...billFormData, [field.id]: e.target.value })}
                      placeholder={field.placeholder}
                      className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                    />
                  ) : field.inputType === 'phone' ? (
                    <input
                      type="tel"
                      value={billFormData[field.id] || ''}
                      onChange={(e) => setBillFormData({ ...billFormData, [field.id]: e.target.value })}
                      placeholder={field.placeholder || '(555) 555-5555'}
                      className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                    />
                  ) : (
                    <input
                      type="text"
                      value={billFormData[field.id] || ''}
                      onChange={(e) => setBillFormData({ ...billFormData, [field.id]: e.target.value })}
                      placeholder={field.placeholder}
                      className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none"
                    />
                  )}

                  {field.helpText && (
                    <p className="text-xs text-gray-500 mt-1">{field.helpText}</p>
                  )}
                </div>
              ))}
            </div>

            <div className="p-6 border-t border-gray-100 flex gap-3">
              <button
                onClick={() => {
                  setShowAddBill(false);
                  setSelectedBillTemplate(null);
                  setBillFormData({});
                }}
                className="flex-1 px-4 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              <button
                onClick={handleAddBill}
                disabled={isSaving}
                className="flex-1 px-4 py-2.5 bg-haven-navy-900 text-white rounded-xl font-medium hover:bg-haven-navy-800 transition disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {isSaving ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Check className="w-4 h-4" />
                    Add Bill
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Monthly Funding Calculator Modal */}
      {showFundingCalc && billSummary && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-lg">
            <div className="p-6 border-b border-gray-100">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-haven-navy-900">Monthly Funding Calculator</h2>
                <button
                  onClick={() => setShowFundingCalc(false)}
                  className="p-2 hover:bg-gray-100 rounded-lg transition"
                >
                  <X className="w-5 h-5 text-gray-500" />
                </button>
              </div>
            </div>

            <div className="p-6">
              {/* Category Breakdown */}
              <div className="space-y-3 mb-6">
                {Object.entries(billSummary.summary).map(([key, data]) => {
                  if (data.count === 0) return null;
                  const config = CATEGORY_CONFIG[key] || { label: key, color: 'bg-gray-100' };
                  return (
                    <div key={key} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                      <span className="text-sm text-gray-700">{config.label}</span>
                      <span className="font-medium">{formatCurrency(data.monthlyTotal)}/mo</span>
                    </div>
                  );
                })}
              </div>

              {/* Totals */}
              <div className="space-y-3 pt-4 border-t border-gray-200">
                <div className="flex justify-between">
                  <span className="text-gray-600">Subtotal</span>
                  <span className="font-medium">{formatCurrency(billSummary.havenManagedTotal)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Haven Service Fee (3%)</span>
                  <span className="font-medium">{formatCurrency(billSummary.havenServiceFee)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Recommended Buffer (10%)</span>
                  <span className="font-medium">{formatCurrency(billSummary.recommendedBuffer)}</span>
                </div>
              </div>

              {/* Final Total */}
              <div className="mt-6 p-4 bg-haven-champagne-50 rounded-xl">
                <div className="flex justify-between items-center">
                  <span className="font-semibold text-haven-navy-900">Monthly Funding Required</span>
                  <span className="text-2xl font-bold text-haven-champagne-600">
                    {formatCurrency(billSummary.recommendedMonthlyFunding)}
                  </span>
                </div>
              </div>
            </div>

            <div className="p-6 border-t border-gray-100">
              <button
                onClick={() => setShowFundingCalc(false)}
                className="w-full px-4 py-2.5 bg-haven-navy-900 text-white rounded-xl font-medium hover:bg-haven-navy-800 transition"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
