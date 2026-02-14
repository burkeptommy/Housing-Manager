import { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../src/components/ScreenContainer';
import { colors, spacing, typography, borderRadius, shadows } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

interface RecurringPayment {
  id: string;
  name: string;
  amount: number;
  frequency: string;
  category: string;
  categoryName: string;
  nextDueDate: string | null;
  trend: 'up' | 'down' | 'stable';
  monthlyEquivalent: number;
  source: string;
}

interface RecurringData {
  payments: RecurringPayment[];
  summary: {
    monthlyTotal: number;
    annualTotal: number;
    count: number;
  };
  byCategory: Array<{
    categoryId: string;
    name: string;
    monthlyTotal: number;
    count: number;
  }>;
}

function formatCurrency(amount: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

function formatDueDate(dateStr: string | null) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function formatFrequency(freq: string) {
  const map: Record<string, string> = {
    weekly: 'Weekly',
    biweekly: 'Every 2 wks',
    monthly: 'Monthly',
    quarterly: 'Quarterly',
    semiannual: 'Every 6 mo',
    annual: 'Annual',
    yearly: 'Annual',
  };
  return map[freq.toLowerCase()] || freq;
}

export default function RecurringPaymentsScreen() {
  const router = useRouter();
  const [data, setData] = useState<RecurringData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const res = await fetch(`${API_BASE_URL}/budgeting/recurring`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        setData(await res.json());
      }
    } catch (err) {
      console.error('Recurring fetch error:', err);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
  }, [fetchData]);

  return (
    <ScreenContainer
      title="Recurring Payments"
      showBack={true}
      onBackPress={() => router.back()}
      refreshing={refreshing}
      onRefresh={onRefresh}
    >
      {isLoading ? (
        <View style={styles.loading}>
          <ActivityIndicator size="large" color={colors.haven.purple[500]} />
        </View>
      ) : !data || data.payments.length === 0 ? (
        <View style={styles.emptyState}>
          <Ionicons name="repeat-outline" size={48} color={colors.slate[300]} />
          <Text style={styles.emptyTitle}>No recurring payments</Text>
          <Text style={styles.emptySubtext}>
            Connect your bank to automatically detect recurring bills and subscriptions.
          </Text>
        </View>
      ) : (
        <View style={styles.content}>
          {/* Summary Card */}
          <View style={styles.summaryCard}>
            <View style={styles.summaryMain}>
              <Text style={styles.summaryLabel}>Monthly Total</Text>
              <Text style={styles.summaryAmount}>
                {formatCurrency(data.summary.monthlyTotal)}
              </Text>
            </View>
            <View style={styles.summaryDivider} />
            <View style={styles.summarySecondary}>
              <View style={styles.summaryItem}>
                <Text style={styles.summaryItemLabel}>Annual</Text>
                <Text style={styles.summaryItemValue}>
                  {formatCurrency(data.summary.annualTotal)}
                </Text>
              </View>
              <View style={styles.summaryItem}>
                <Text style={styles.summaryItemLabel}>Bills</Text>
                <Text style={styles.summaryItemValue}>{data.summary.count}</Text>
              </View>
            </View>
          </View>

          {/* Category Breakdown */}
          {data.byCategory.length > 0 && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>By Category</Text>
              {data.byCategory.map((cat) => {
                const pct = data.summary.monthlyTotal > 0
                  ? (cat.monthlyTotal / data.summary.monthlyTotal) * 100
                  : 0;
                return (
                  <View key={cat.categoryId} style={styles.catRow}>
                    <View style={styles.catInfo}>
                      <Text style={styles.catName}>{cat.name}</Text>
                      <Text style={styles.catCount}>{cat.count} bill{cat.count !== 1 ? 's' : ''}</Text>
                    </View>
                    <View style={styles.catBarContainer}>
                      <View style={styles.catBar}>
                        <View style={[styles.catBarFill, { width: `${pct}%` }]} />
                      </View>
                    </View>
                    <Text style={styles.catAmount}>{formatCurrency(cat.monthlyTotal)}</Text>
                  </View>
                );
              })}
            </View>
          )}

          {/* Payment List */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>All Payments</Text>
            {data.payments.map((payment) => (
              <View key={payment.id} style={styles.paymentRow}>
                <View style={styles.paymentIcon}>
                  <Ionicons name="repeat-outline" size={16} color={colors.haven.purple[500]} />
                </View>
                <View style={styles.paymentInfo}>
                  <Text style={styles.paymentName} numberOfLines={1}>{payment.name}</Text>
                  <Text style={styles.paymentMeta}>
                    {formatFrequency(payment.frequency)}
                    {payment.nextDueDate ? ` · Next: ${formatDueDate(payment.nextDueDate)}` : ''}
                  </Text>
                </View>
                <View style={styles.paymentRight}>
                  <View style={styles.paymentAmountRow}>
                    <Text style={styles.paymentAmount}>{formatCurrency(payment.amount)}</Text>
                    {payment.trend !== 'stable' && (
                      <Ionicons
                        name={payment.trend === 'up' ? 'caret-up' : 'caret-down'}
                        size={12}
                        color={payment.trend === 'up' ? colors.status.error : colors.status.success}
                      />
                    )}
                  </View>
                  {payment.frequency !== 'monthly' && (
                    <Text style={styles.paymentMonthly}>
                      {formatCurrency(payment.monthlyEquivalent)}/mo
                    </Text>
                  )}
                </View>
              </View>
            ))}
          </View>
        </View>
      )}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  content: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  loading: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingTop: spacing[12],
  },

  // Summary
  summaryCard: {
    backgroundColor: colors.haven.purple[800],
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    marginBottom: spacing[4],
  },
  summaryMain: {
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  summaryLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[200],
  },
  summaryAmount: {
    fontSize: 36,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    marginTop: spacing[1],
  },
  summaryDivider: {
    height: 1,
    backgroundColor: 'rgba(255,255,255,0.15)',
    marginBottom: spacing[4],
  },
  summarySecondary: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  summaryItem: {
    alignItems: 'center',
  },
  summaryItemLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[300],
  },
  summaryItemValue: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
    marginTop: 2,
  },

  // Section
  section: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginBottom: spacing[4],
    ...shadows.sm,
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginBottom: spacing[3],
  },

  // Category breakdown
  catRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    gap: spacing[3],
  },
  catInfo: {
    width: 90,
  },
  catName: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[700],
    fontWeight: typography.fontWeights.medium,
  },
  catCount: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginTop: 1,
  },
  catBarContainer: {
    flex: 1,
  },
  catBar: {
    height: 8,
    backgroundColor: colors.slate[100],
    borderRadius: 4,
    overflow: 'hidden',
  },
  catBarFill: {
    height: '100%',
    backgroundColor: colors.haven.purple[500],
    borderRadius: 4,
  },
  catAmount: {
    width: 65,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    textAlign: 'right',
  },

  // Payment list
  paymentRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[50],
    gap: spacing[3],
  },
  paymentIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  paymentInfo: {
    flex: 1,
  },
  paymentName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  paymentMeta: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  paymentRight: {
    alignItems: 'flex-end',
  },
  paymentAmountRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  paymentAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  paymentMonthly: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginTop: 2,
  },

  // Empty
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[12],
    paddingHorizontal: spacing[6],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[600],
    marginTop: spacing[4],
  },
  emptySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[400],
    textAlign: 'center',
    marginTop: spacing[2],
    maxWidth: 280,
  },
});
