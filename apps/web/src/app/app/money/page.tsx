'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { Card, Badge, Button } from '@/components/ui';
import {
  DollarSign,
  CreditCard,
  Home,
  Zap,
  Shield,
  Sparkles,
  GraduationCap,
  PawPrint,
  Wrench,
  Car,
  Heart,
  ChevronDown,
  ChevronUp,
  CheckCircle2,
  Clock,
  AlertCircle,
  Download,
  Loader2,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface Bill {
  id: string;
  category: string;
  name: string;
  payeeName: string | null;
  amount: number;
  frequency: string | null;
  dueDay: number | null;
  status: string;
  havenManaged: boolean;
  verified: boolean;
  currentAutopay: boolean;
  vendor: string | null;
  lastPayment: {
    amount: number;
    date: string;
    status: string;
  } | null;
}

interface CategorySummary {
  category: string;
  billCount: number;
  monthlyTotal: number;
}

interface BillsData {
  bills: Bill[];
  byCategory: CategorySummary[];
  summary: {
    totalBills: number;
    monthlyTotal: number;
    monthlyFunding: number;
  };
}

// ============================================================================
// HELPERS
// ============================================================================

function formatCurrency(amount: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

function getCategoryIcon(category: string) {
  const cat = category.toUpperCase();
  if (cat.includes('MORTGAGE') || cat.includes('HOUSING') || cat.includes('RENT')) {
    return <Home className="w-5 h-5" />;
  }
  if (cat.includes('UTILITY') || cat.includes('ELECTRIC') || cat.includes('GAS') || cat.includes('WATER')) {
    return <Zap className="w-5 h-5" />;
  }
  if (cat.includes('INSURANCE')) {
    return <Shield className="w-5 h-5" />;
  }
  if (cat.includes('SERVICE') || cat.includes('CLEANING') || cat.includes('LAWN')) {
    return <Sparkles className="w-5 h-5" />;
  }
  if (cat.includes('KID') || cat.includes('ACTIVITY') || cat.includes('SCHOOL') || cat.includes('TUITION')) {
    return <GraduationCap className="w-5 h-5" />;
  }
  if (cat.includes('PET')) {
    return <PawPrint className="w-5 h-5" />;
  }
  if (cat.includes('VEHICLE') || cat.includes('AUTO') || cat.includes('CAR')) {
    return <Car className="w-5 h-5" />;
  }
  if (cat.includes('HEALTH') || cat.includes('MEDICAL')) {
    return <Heart className="w-5 h-5" />;
  }
  if (cat.includes('MAINTENANCE') || cat.includes('REPAIR')) {
    return <Wrench className="w-5 h-5" />;
  }
  return <DollarSign className="w-5 h-5" />;
}

function getCategoryColor(category: string) {
  const cat = category.toUpperCase();
  if (cat.includes('MORTGAGE') || cat.includes('HOUSING')) {
    return { bg: 'bg-indigo-100', text: 'text-indigo-700' };
  }
  if (cat.includes('UTILITY')) {
    return { bg: 'bg-amber-100', text: 'text-amber-700' };
  }
  if (cat.includes('INSURANCE')) {
    return { bg: 'bg-emerald-100', text: 'text-emerald-700' };
  }
  if (cat.includes('SERVICE')) {
    return { bg: 'bg-purple-100', text: 'text-purple-700' };
  }
  if (cat.includes('KID') || cat.includes('ACTIVITY')) {
    return { bg: 'bg-pink-100', text: 'text-pink-700' };
  }
  if (cat.includes('PET')) {
    return { bg: 'bg-orange-100', text: 'text-orange-700' };
  }
  if (cat.includes('VEHICLE')) {
    return { bg: 'bg-blue-100', text: 'text-blue-700' };
  }
  return { bg: 'bg-gray-100', text: 'text-gray-700' };
}

function formatCategoryName(category: string) {
  return category
    .split('_')
    .map((word) => word.charAt(0) + word.slice(1).toLowerCase())
    .join(' ');
}

// ============================================================================
// COMPONENTS
// ============================================================================

function PageSkeleton() {
  return (
    <div className="pb-32 lg:pb-8 max-w-4xl mx-auto animate-pulse">
      <div className="h-48 bg-gray-200 rounded-2xl mb-6" />
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-24 bg-gray-200 rounded-xl" />
        ))}
      </div>
    </div>
  );
}

function SummaryHeader({ summary }: { summary: BillsData['summary'] }) {
  const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long' });

  return (
    <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-haven-700 via-haven-700 to-haven-800 p-6 text-white mb-6">
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 right-0 w-64 h-64 bg-white rounded-full -translate-y-1/2 translate-x-1/2" />
      </div>
      <div className="relative">
        <div className="flex items-center gap-2 text-haven-100 text-sm mb-2">
          <CreditCard className="w-4 h-4" />
          {currentMonth} Bills
        </div>
        <div className="text-4xl font-bold mb-2">{formatCurrency(summary.monthlyTotal)}</div>
        <p className="text-haven-100 mb-4">
          {summary.totalBills} active bill{summary.totalBills !== 1 ? 's' : ''} managed by Haven
        </p>

        {/* Funding Progress */}
        {summary.monthlyFunding > 0 && (
          <div className="bg-white/10 rounded-xl p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-haven-100">Monthly Funding</span>
              <span className="font-semibold">{formatCurrency(summary.monthlyFunding)}</span>
            </div>
            <div className="w-full bg-white/20 rounded-full h-2">
              <div
                className="bg-green-400 h-2 rounded-full"
                style={{
                  width: `${Math.min((summary.monthlyTotal / summary.monthlyFunding) * 100, 100)}%`,
                }}
              />
            </div>
            <p className="text-xs text-haven-100 mt-2">
              {summary.monthlyFunding > summary.monthlyTotal
                ? `${formatCurrency(summary.monthlyFunding - summary.monthlyTotal)} buffer remaining`
                : 'Bills exceed funding amount'}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

function CategoryCard({
  category,
  bills,
  isExpanded,
  onToggle,
}: {
  category: CategorySummary;
  bills: Bill[];
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const colors = getCategoryColor(category.category);
  const icon = getCategoryIcon(category.category);

  return (
    <Card className="overflow-hidden">
      <button
        onClick={onToggle}
        className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors"
      >
        <div className="flex items-center gap-3">
          <div className={`p-2.5 rounded-xl ${colors.bg}`}>
            <div className={colors.text}>{icon}</div>
          </div>
          <div className="text-left">
            <div className="font-medium text-gray-900">
              {formatCategoryName(category.category)}
            </div>
            <div className="text-sm text-gray-500">
              {category.billCount} bill{category.billCount !== 1 ? 's' : ''}
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <span className="font-semibold text-gray-900">
            {formatCurrency(category.monthlyTotal)}/mo
          </span>
          {isExpanded ? (
            <ChevronUp className="w-5 h-5 text-gray-400" />
          ) : (
            <ChevronDown className="w-5 h-5 text-gray-400" />
          )}
        </div>
      </button>

      {isExpanded && (
        <div className="px-4 pb-4">
          <div className="border-t border-gray-100 pt-3 space-y-2">
            {bills.map((bill) => (
              <div
                key={bill.id}
                className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
              >
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-gray-900">{bill.name}</span>
                    {bill.havenManaged && (
                      <Badge variant="success" size="sm">Haven Managed</Badge>
                    )}
                  </div>
                  {bill.payeeName && (
                    <div className="text-sm text-gray-500">{bill.payeeName}</div>
                  )}
                </div>
                <div className="text-right">
                  <div className="font-medium text-gray-900">
                    {formatCurrency(bill.amount)}
                    <span className="text-xs text-gray-400 ml-1">
                      /{bill.frequency?.toLowerCase() || 'mo'}
                    </span>
                  </div>
                  {bill.dueDay && (
                    <div className="text-xs text-gray-500">
                      Due day {bill.dueDay}
                    </div>
                  )}
                  {bill.lastPayment && (
                    <div className="flex items-center gap-1 text-xs text-green-600 mt-1">
                      <CheckCircle2 className="w-3 h-3" />
                      Paid {new Date(bill.lastPayment.date).toLocaleDateString()}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </Card>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function MoneyPage() {
  const { getIdToken, householdId } = useAuth();
  const [data, setData] = useState<BillsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (householdId) {
      fetchBills();
    }
  }, [householdId]);

  const fetchBills = async () => {
    try {
      const token = await getIdToken();
      if (!token || !householdId) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/dashboard/household/${householdId}/bills`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to load bills');
      }

      const result = await response.json();
      setData(result);

      // Expand first category by default
      if (result.byCategory.length > 0) {
        setExpandedCategories(new Set([result.byCategory[0].category]));
      }
    } catch (err) {
      console.error('Bills error:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  const toggleCategory = (category: string) => {
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

  const getBillsForCategory = (category: string) => {
    return data?.bills.filter((b) => b.category === category) || [];
  };

  if (loading) return <PageSkeleton />;

  if (error) {
    return (
      <div className="p-6 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
        <p className="text-red-600 mb-4">Error loading bills: {error}</p>
        <Button onClick={fetchBills}>Try Again</Button>
      </div>
    );
  }

  if (!data || data.bills.length === 0) {
    return (
      <div className="pb-32 lg:pb-8 max-w-4xl mx-auto">
        <div className="text-center py-12">
          <CreditCard className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500 mb-2">No bills set up yet</p>
          <p className="text-sm text-gray-400">
            Your Home Manager will add your bills during onboarding.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="pb-32 lg:pb-8 max-w-4xl mx-auto">
      <SummaryHeader summary={data.summary} />

      {/* Bills by Category */}
      <div className="space-y-4 mb-6">
        {data.byCategory.map((category) => (
          <CategoryCard
            key={category.category}
            category={category}
            bills={getBillsForCategory(category.category)}
            isExpanded={expandedCategories.has(category.category)}
            onToggle={() => toggleCategory(category.category)}
          />
        ))}
      </div>

      {/* Quick Actions */}
      <Card>
        <div className="flex items-center justify-between p-4">
          <div>
            <h3 className="font-semibold text-gray-900">Monthly Statement</h3>
            <p className="text-sm text-gray-500">Download your detailed bill statement</p>
          </div>
          <Button variant="outline" leftIcon={<Download className="w-4 h-4" />}>
            Download PDF
          </Button>
        </div>
      </Card>
    </div>
  );
}
