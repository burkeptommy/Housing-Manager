import { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  RefreshControl,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { colors, spacing, typography, borderRadius, shadows } from '../../src/lib/theme';
import { API_BASE_URL } from '../../src/lib/api';
import { getIdToken } from '../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

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

// =============================================================================
// HELPERS
// =============================================================================

function formatCurrency(amount: number | null | undefined) {
  if (amount === null || amount === undefined) return '$0';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

function formatCurrencyDetailed(amount: number | null | undefined) {
  if (amount === null || amount === undefined) return '$0.00';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

function getCategoryIcon(category: string): keyof typeof Ionicons.glyphMap {
  const cat = category.toUpperCase();
  if (cat.includes('MORTGAGE') || cat.includes('HOUSING') || cat.includes('RENT')) {
    return 'home-outline';
  }
  if (cat.includes('UTILITY') || cat.includes('ELECTRIC') || cat.includes('GAS') || cat.includes('WATER')) {
    return 'flash-outline';
  }
  if (cat.includes('INSURANCE')) {
    return 'shield-outline';
  }
  if (cat.includes('SERVICE') || cat.includes('CLEANING') || cat.includes('LAWN')) {
    return 'sparkles-outline';
  }
  if (cat.includes('KID') || cat.includes('ACTIVITY') || cat.includes('SCHOOL') || cat.includes('TUITION')) {
    return 'school-outline';
  }
  if (cat.includes('PET')) {
    return 'paw-outline';
  }
  if (cat.includes('VEHICLE') || cat.includes('AUTO') || cat.includes('CAR')) {
    return 'car-outline';
  }
  if (cat.includes('HEALTH') || cat.includes('MEDICAL')) {
    return 'heart-outline';
  }
  if (cat.includes('MAINTENANCE') || cat.includes('REPAIR')) {
    return 'construct-outline';
  }
  return 'cash-outline';
}

function getCategoryColor(category: string) {
  const cat = category.toUpperCase();
  if (cat.includes('MORTGAGE') || cat.includes('HOUSING')) {
    return { bg: '#E0E7FF', text: '#4338CA' }; // indigo
  }
  if (cat.includes('UTILITY')) {
    return { bg: '#FEF3C7', text: '#B45309' }; // amber
  }
  if (cat.includes('INSURANCE')) {
    return { bg: '#F5F0E6', text: '#8B7355' }; // champagne
  }
  if (cat.includes('SERVICE')) {
    return { bg: '#F3E8FF', text: '#7C3AED' }; // purple
  }
  if (cat.includes('KID') || cat.includes('ACTIVITY')) {
    return { bg: '#FCE7F3', text: '#BE185D' }; // pink
  }
  if (cat.includes('PET')) {
    return { bg: '#FFEDD5', text: '#C2410C' }; // orange
  }
  if (cat.includes('VEHICLE')) {
    return { bg: '#DBEAFE', text: '#1D4ED8' }; // blue
  }
  return { bg: colors.slate[100], text: colors.slate[700] };
}

function formatCategoryName(category: string) {
  return category
    .split('_')
    .map((word) => word.charAt(0) + word.slice(1).toLowerCase())
    .join(' ');
}

function formatFrequency(freq: string | null) {
  if (!freq) return 'mo';
  const map: Record<string, string> = {
    WEEKLY: 'wk',
    BIWEEKLY: '2wk',
    SEMI_MONTHLY: '2x/mo',
    MONTHLY: 'mo',
    QUARTERLY: 'qtr',
    ANNUALLY: 'yr',
  };
  return map[freq] || 'mo';
}

// =============================================================================
// COMPONENTS
// =============================================================================

function SummaryHeader({ summary }: { summary: BillsData['summary'] }) {
  const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long' });
  const progress = summary.monthlyFunding > 0
    ? Math.min((summary.monthlyTotal / summary.monthlyFunding) * 100, 100)
    : 0;
  const buffer = summary.monthlyFunding - summary.monthlyTotal;

  return (
    <View style={styles.summaryCard}>
      <View style={styles.summaryHeader}>
        <View style={styles.summaryLabel}>
          <Ionicons name="card-outline" size={16} color={colors.haven.champagne[200]} />
          <Text style={styles.summaryLabelText}>{currentMonth} Bills</Text>
        </View>
      </View>
      <Text style={styles.summaryAmount}>{formatCurrency(summary.monthlyTotal)}</Text>
      <Text style={styles.summarySubtext}>
        {summary.totalBills} active bill{summary.totalBills !== 1 ? 's' : ''} managed by Haven
      </Text>

      {summary.monthlyFunding > 0 && (
        <View style={styles.fundingSection}>
          <View style={styles.fundingHeader}>
            <Text style={styles.fundingLabel}>Monthly Funding</Text>
            <Text style={styles.fundingAmount}>{formatCurrency(summary.monthlyFunding)}</Text>
          </View>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: `${progress}%` }]} />
          </View>
          <Text style={styles.fundingBuffer}>
            {buffer > 0
              ? `${formatCurrency(buffer)} buffer remaining`
              : 'Bills exceed funding amount'}
          </Text>
        </View>
      )}
    </View>
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
  const categoryColors = getCategoryColor(category.category);
  const icon = getCategoryIcon(category.category);

  return (
    <View style={styles.categoryCard}>
      <TouchableOpacity
        style={styles.categoryHeader}
        onPress={onToggle}
        activeOpacity={0.7}
      >
        <View style={styles.categoryLeft}>
          <View style={[styles.categoryIcon, { backgroundColor: categoryColors.bg }]}>
            <Ionicons name={icon} size={20} color={categoryColors.text} />
          </View>
          <View>
            <Text style={styles.categoryName}>{formatCategoryName(category.category)}</Text>
            <Text style={styles.categoryCount}>
              {category.billCount} bill{category.billCount !== 1 ? 's' : ''}
            </Text>
          </View>
        </View>
        <View style={styles.categoryRight}>
          <Text style={styles.categoryTotal}>{formatCurrency(category.monthlyTotal)}/mo</Text>
          <Ionicons
            name={isExpanded ? 'chevron-up' : 'chevron-down'}
            size={20}
            color={colors.slate[400]}
          />
        </View>
      </TouchableOpacity>

      {isExpanded && bills.length > 0 && (
        <View style={styles.billsList}>
          {bills.map((bill) => (
            <View key={bill.id} style={styles.billItem}>
              <View style={styles.billInfo}>
                <View style={styles.billNameRow}>
                  <Text style={styles.billName}>{bill.name}</Text>
                  {bill.havenManaged && (
                    <View style={styles.havenBadge}>
                      <Text style={styles.havenBadgeText}>Haven Managed</Text>
                    </View>
                  )}
                </View>
                {bill.payeeName && (
                  <Text style={styles.billPayee}>{bill.payeeName}</Text>
                )}
              </View>
              <View style={styles.billRight}>
                <Text style={styles.billAmount}>
                  {formatCurrencyDetailed(bill.amount)}
                  <Text style={styles.billFrequency}>/{formatFrequency(bill.frequency)}</Text>
                </Text>
                {bill.dueDay && (
                  <Text style={styles.billDue}>Due day {bill.dueDay}</Text>
                )}
                {bill.lastPayment && (
                  <View style={styles.paidRow}>
                    <Ionicons name="checkmark-circle" size={12} color={colors.status.success} />
                    <Text style={styles.paidText}>
                      Paid {new Date(bill.lastPayment.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                    </Text>
                  </View>
                )}
              </View>
            </View>
          ))}
        </View>
      )}
    </View>
  );
}

function EmptyState() {
  return (
    <View style={styles.emptyState}>
      <Ionicons name="card-outline" size={48} color={colors.slate[300]} />
      <Text style={styles.emptyTitle}>No bills set up yet</Text>
      <Text style={styles.emptySubtext}>
        Your Home Manager will add your bills during onboarding.
      </Text>
    </View>
  );
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export default function BillingScreen() {
  const { householdInfo } = useAuth();
  const [data, setData] = useState<BillsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set());

  const fetchBills = useCallback(async () => {
    if (!householdInfo?.id) {
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/dashboard/household/${householdInfo.id}/bills`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to load bills');
      }

      const result: BillsData = await response.json();
      setData(result);

      // Expand first category by default
      if (result.byCategory.length > 0) {
        setExpandedCategories(new Set([result.byCategory[0].category]));
      }
    } catch (err) {
      console.error('Bills error:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setIsLoading(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchBills();
  }, [fetchBills]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await fetchBills();
    setRefreshing(false);
  }, [fetchBills]);

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

  if (isLoading) {
    return (
      <SafeAreaView style={styles.loadingContainer} edges={['bottom']}>
        <ActivityIndicator size="large" color={colors.haven.champagne[500]} />
      </SafeAreaView>
    );
  }

  if (!householdInfo?.id) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <View style={styles.centerContent}>
          <Ionicons name="wallet-outline" size={48} color={colors.slate[300]} />
          <Text style={styles.emptyTitle}>No household found</Text>
          <Text style={styles.emptySubtext}>Complete onboarding to view billing</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (error) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <View style={styles.centerContent}>
          <Ionicons name="alert-circle-outline" size={48} color={colors.status.error} />
          <Text style={[styles.emptyTitle, { color: colors.status.error }]}>Error loading bills</Text>
          <Text style={styles.emptySubtext}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchBills}>
            <Text style={styles.retryButtonText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  if (!data || data.bills.length === 0) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor={colors.haven.champagne[500]}
            />
          }
        >
          <EmptyState />
        </ScrollView>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={colors.haven.champagne[500]}
          />
        }
      >
        {/* Summary Header */}
        <SummaryHeader summary={data.summary} />

        {/* Bills by Category */}
        <View style={styles.categoriesSection}>
          {data.byCategory.map((category) => (
            <CategoryCard
              key={category.category}
              category={category}
              bills={getBillsForCategory(category.category)}
              isExpanded={expandedCategories.has(category.category)}
              onToggle={() => toggleCategory(category.category)}
            />
          ))}
        </View>

        {/* Quick Actions */}
        <View style={styles.quickActions}>
          <TouchableOpacity style={styles.actionCard}>
            <View style={styles.actionContent}>
              <View>
                <Text style={styles.actionTitle}>Monthly Statement</Text>
                <Text style={styles.actionSubtitle}>Download your detailed bill statement</Text>
              </View>
              <View style={styles.actionButton}>
                <Ionicons name="download-outline" size={20} color={colors.haven.navy[700]} />
                <Text style={styles.actionButtonText}>PDF</Text>
              </View>
            </View>
          </TouchableOpacity>
        </View>

        {/* Info Banner */}
        <View style={styles.infoBanner}>
          <Ionicons name="information-circle-outline" size={20} color={colors.haven.navy[600]} />
          <Text style={styles.infoBannerText}>
            Haven automatically pays your bills on time. Sit back and relax!
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.slate[50],
  },
  centerContent: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },

  // Summary Header
  summaryCard: {
    backgroundColor: colors.haven.navy[800],
    borderRadius: borderRadius.xl,
    padding: spacing[6],
    marginBottom: spacing[6],
    overflow: 'hidden',
  },
  summaryHeader: {
    marginBottom: spacing[2],
  },
  summaryLabel: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  summaryLabelText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[200],
  },
  summaryAmount: {
    fontSize: 40,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    marginBottom: spacing[1],
  },
  summarySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[200],
    marginBottom: spacing[4],
  },
  fundingSection: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: borderRadius.lg,
    padding: spacing[4],
  },
  fundingHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  fundingLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[200],
  },
  fundingAmount: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  progressBar: {
    height: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: borderRadius.full,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.full,
  },
  fundingBuffer: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.champagne[200],
    marginTop: spacing[2],
  },

  // Categories Section
  categoriesSection: {
    gap: spacing[4],
    marginBottom: spacing[6],
  },
  categoryCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    overflow: 'hidden',
    ...shadows.sm,
  },
  categoryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
  },
  categoryLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
  },
  categoryIcon: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  categoryName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  categoryCount: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  categoryRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  categoryTotal: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },

  // Bills List (expanded)
  billsList: {
    borderTopWidth: 1,
    borderTopColor: colors.slate[100],
    paddingHorizontal: spacing[4],
    paddingBottom: spacing[4],
  },
  billItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[3],
  },
  billInfo: {
    flex: 1,
    marginRight: spacing[3],
  },
  billNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  billName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  havenBadge: {
    backgroundColor: colors.status.success + '20',
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
  },
  havenBadgeText: {
    fontSize: 10,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.success,
  },
  billPayee: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  billRight: {
    alignItems: 'flex-end',
  },
  billAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  billFrequency: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.normal,
    color: colors.slate[400],
  },
  billDue: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  paidRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 4,
  },
  paidText: {
    fontSize: typography.fontSizes.xs,
    color: colors.status.success,
  },

  // Quick Actions
  quickActions: {
    marginBottom: spacing[4],
  },
  actionCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    ...shadows.sm,
  },
  actionContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  actionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  actionSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    backgroundColor: colors.slate[100],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
  },
  actionButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[700],
  },

  // Info Banner
  infoBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    backgroundColor: colors.haven.navy[50],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    borderWidth: 1,
    borderColor: colors.haven.navy[100],
  },
  infoBannerText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[700],
    lineHeight: 20,
  },

  // Empty State
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[12],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[600],
    marginTop: spacing[4],
    textAlign: 'center',
  },
  emptySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[400],
    marginTop: spacing[2],
    textAlign: 'center',
    maxWidth: 280,
  },

  // Retry Button
  retryButton: {
    backgroundColor: colors.haven.champagne[500],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
  },
  retryButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
});
