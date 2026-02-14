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

interface RefinancingOpportunity {
  id: string;
  name: string;
  category: string;
  currentRate: number;
  marketRate: number;
  balance: number;
  currentMonthly: number;
  estimatedNewMonthly: number;
  monthlySavings: number;
  lifetimeSavings: number;
  breakEvenMonths: number;
}

interface RateOptimization {
  category: string;
  name: string;
  color: string;
  currentCost: number;
  localMedian: number;
  percentOver: number;
  potentialSavings: number;
  suggestion: string;
}

interface SubscriptionItem {
  id: string;
  name: string;
  amount: number;
  frequency: string;
}

interface SavingsSummary {
  totalMonthlySavings: number;
  totalAnnualSavings: number;
  refinancing: {
    count: number;
    monthlySavings: number;
    topOpportunity: RefinancingOpportunity | null;
  };
  rateOptimization: {
    count: number;
    monthlySavings: number;
    topCategory: RateOptimization | null;
  };
  subscriptions: {
    count: number;
    monthlyTotal: number;
    items: SubscriptionItem[];
  };
  insuranceBundling: {
    canBundle: boolean;
    providerCount: number;
    potentialSavings: number;
  };
}

function formatCurrency(amount: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

export default function InsightsScreen() {
  const router = useRouter();
  const [data, setData] = useState<SavingsSummary | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const res = await fetch(`${API_BASE_URL}/budgeting/savings-summary`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        setData(await res.json());
      }
    } catch (err) {
      console.error('Savings insights fetch error:', err);
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

  const hasSavings = data && data.totalMonthlySavings > 0;
  const hasSubscriptions = data && data.subscriptions.count > 0;

  return (
    <ScreenContainer
      title="Savings Insights"
      showBack={true}
      onBackPress={() => router.back()}
      refreshing={refreshing}
      onRefresh={onRefresh}
    >
      {isLoading ? (
        <View style={styles.loading}>
          <ActivityIndicator size="large" color={colors.haven.purple[500]} />
        </View>
      ) : !data ? (
        <View style={styles.emptyState}>
          <Ionicons name="bulb-outline" size={48} color={colors.slate[300]} />
          <Text style={styles.emptyTitle}>No savings data yet</Text>
          <Text style={styles.emptySubtext}>
            Connect your bank and add bills to unlock personalized savings insights.
          </Text>
        </View>
      ) : (
        <View style={styles.content}>
          {/* Savings Hero */}
          <View style={styles.heroCard}>
            <Text style={styles.heroLabel}>Potential Savings</Text>
            <Text style={styles.heroAmount}>
              {formatCurrency(data.totalMonthlySavings)}/mo
            </Text>
            <Text style={styles.heroSub}>
              {formatCurrency(data.totalAnnualSavings)} annually
            </Text>
          </View>

          {/* Refinancing Opportunities */}
          {data.refinancing.count > 0 && data.refinancing.topOpportunity && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <View style={[styles.sectionIconBox, { backgroundColor: '#e8f5e9' }]}>
                  <Ionicons name="trending-down-outline" size={18} color="#2e7d32" />
                </View>
                <View style={styles.sectionHeaderText}>
                  <Text style={styles.sectionTitle}>Refinancing</Text>
                  <Text style={styles.sectionSubtitle}>
                    {data.refinancing.count} opportunit{data.refinancing.count === 1 ? 'y' : 'ies'}
                  </Text>
                </View>
                <Text style={styles.sectionSavings}>
                  {formatCurrency(data.refinancing.monthlySavings)}/mo
                </Text>
              </View>

              <View style={styles.opportunityCard}>
                <Text style={styles.oppName}>{data.refinancing.topOpportunity.name}</Text>
                <View style={styles.oppRow}>
                  <View style={styles.oppCol}>
                    <Text style={styles.oppLabel}>Current Rate</Text>
                    <Text style={styles.oppValue}>{data.refinancing.topOpportunity.currentRate}%</Text>
                  </View>
                  <View style={styles.oppArrow}>
                    <Ionicons name="arrow-forward" size={16} color={colors.slate[400]} />
                  </View>
                  <View style={styles.oppCol}>
                    <Text style={styles.oppLabel}>Market Rate</Text>
                    <Text style={[styles.oppValue, { color: '#2e7d32' }]}>
                      {data.refinancing.topOpportunity.marketRate}%
                    </Text>
                  </View>
                </View>
                <View style={styles.oppStats}>
                  <View style={styles.oppStat}>
                    <Text style={styles.oppStatLabel}>Monthly Savings</Text>
                    <Text style={styles.oppStatValue}>
                      {formatCurrency(data.refinancing.topOpportunity.monthlySavings)}
                    </Text>
                  </View>
                  <View style={styles.oppStat}>
                    <Text style={styles.oppStatLabel}>Break Even</Text>
                    <Text style={styles.oppStatValue}>
                      {data.refinancing.topOpportunity.breakEvenMonths} mo
                    </Text>
                  </View>
                  <View style={styles.oppStat}>
                    <Text style={styles.oppStatLabel}>5-Year Savings</Text>
                    <Text style={styles.oppStatValue}>
                      {formatCurrency(data.refinancing.topOpportunity.lifetimeSavings)}
                    </Text>
                  </View>
                </View>
              </View>
            </View>
          )}

          {/* Rate Optimization */}
          {data.rateOptimization.count > 0 && data.rateOptimization.topCategory && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <View style={[styles.sectionIconBox, { backgroundColor: '#fff3e0' }]}>
                  <Ionicons name="flash-outline" size={18} color="#e65100" />
                </View>
                <View style={styles.sectionHeaderText}>
                  <Text style={styles.sectionTitle}>Rate Optimization</Text>
                  <Text style={styles.sectionSubtitle}>
                    {data.rateOptimization.count} categor{data.rateOptimization.count === 1 ? 'y' : 'ies'} above local median
                  </Text>
                </View>
                <Text style={styles.sectionSavings}>
                  {formatCurrency(data.rateOptimization.monthlySavings)}/mo
                </Text>
              </View>

              <View style={styles.rateCard}>
                <View style={styles.rateRow}>
                  <Text style={styles.rateName}>{data.rateOptimization.topCategory.name}</Text>
                  <Text style={styles.rateOver}>
                    +{data.rateOptimization.topCategory.percentOver}% above local avg
                  </Text>
                </View>
                <View style={styles.rateComparison}>
                  <View style={styles.rateCol}>
                    <Text style={styles.rateLabel}>You Pay</Text>
                    <Text style={styles.rateAmount}>
                      {formatCurrency(data.rateOptimization.topCategory.currentCost)}
                    </Text>
                  </View>
                  <View style={styles.rateCol}>
                    <Text style={styles.rateLabel}>Local Median</Text>
                    <Text style={[styles.rateAmount, { color: '#2e7d32' }]}>
                      {formatCurrency(data.rateOptimization.topCategory.localMedian)}
                    </Text>
                  </View>
                </View>
                <Text style={styles.rateSuggestion}>
                  {data.rateOptimization.topCategory.suggestion}
                </Text>
              </View>
            </View>
          )}

          {/* Insurance Bundling */}
          {data.insuranceBundling.canBundle && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <View style={[styles.sectionIconBox, { backgroundColor: '#e3f2fd' }]}>
                  <Ionicons name="shield-checkmark-outline" size={18} color="#1565c0" />
                </View>
                <View style={styles.sectionHeaderText}>
                  <Text style={styles.sectionTitle}>Insurance Bundling</Text>
                  <Text style={styles.sectionSubtitle}>
                    {data.insuranceBundling.providerCount} separate providers detected
                  </Text>
                </View>
                <Text style={styles.sectionSavings}>
                  {formatCurrency(data.insuranceBundling.potentialSavings)}/mo
                </Text>
              </View>
              <Text style={styles.bundleHint}>
                Bundle your insurance policies with one provider to save an estimated 15% on premiums.
              </Text>
            </View>
          )}

          {/* Subscriptions */}
          {hasSubscriptions && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <View style={[styles.sectionIconBox, { backgroundColor: '#fce4ec' }]}>
                  <Ionicons name="repeat-outline" size={18} color="#c62828" />
                </View>
                <View style={styles.sectionHeaderText}>
                  <Text style={styles.sectionTitle}>Subscription Audit</Text>
                  <Text style={styles.sectionSubtitle}>
                    {data.subscriptions.count} active subscriptions
                  </Text>
                </View>
                <Text style={styles.sectionSavings}>
                  {formatCurrency(data.subscriptions.monthlyTotal)}/mo
                </Text>
              </View>

              {data.subscriptions.items.slice(0, 8).map((sub) => (
                <View key={sub.id} style={styles.subRow}>
                  <Text style={styles.subName} numberOfLines={1}>{sub.name}</Text>
                  <Text style={styles.subFreq}>{sub.frequency || 'Monthly'}</Text>
                  <Text style={styles.subAmount}>{formatCurrency(sub.amount)}</Text>
                </View>
              ))}
              {data.subscriptions.items.length > 8 && (
                <Text style={styles.moreText}>
                  +{data.subscriptions.items.length - 8} more
                </Text>
              )}
            </View>
          )}

          {/* No savings found */}
          {!hasSavings && !hasSubscriptions && (
            <View style={styles.noSavingsCard}>
              <Ionicons name="checkmark-circle-outline" size={40} color="#2e7d32" />
              <Text style={styles.noSavingsTitle}>Looking good!</Text>
              <Text style={styles.noSavingsText}>
                No obvious savings opportunities detected. We'll keep monitoring and notify you when we find something.
              </Text>
            </View>
          )}
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

  // Hero
  heroCard: {
    backgroundColor: colors.haven.purple[800],
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  heroLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[200],
  },
  heroAmount: {
    fontSize: 36,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    marginTop: spacing[1],
  },
  heroSub: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[300],
    marginTop: spacing[1],
  },

  // Section
  section: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginBottom: spacing[4],
    ...shadows.sm,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[3],
    gap: spacing[3],
  },
  sectionIconBox: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sectionHeaderText: {
    flex: 1,
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  sectionSubtitle: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 1,
  },
  sectionSavings: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.bold,
    color: '#2e7d32',
  },

  // Refinancing
  opportunityCard: {
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
  },
  oppName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginBottom: spacing[2],
  },
  oppRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
    gap: spacing[4],
  },
  oppCol: {
    alignItems: 'center',
  },
  oppArrow: {
    paddingTop: spacing[2],
  },
  oppLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
  },
  oppValue: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
    marginTop: 2,
  },
  oppStats: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    borderTopWidth: 1,
    borderTopColor: colors.slate[200],
    paddingTop: spacing[2],
  },
  oppStat: {
    alignItems: 'center',
  },
  oppStatLabel: {
    fontSize: 10,
    color: colors.slate[400],
  },
  oppStatValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginTop: 2,
  },

  // Rate optimization
  rateCard: {
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
  },
  rateRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  rateName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  rateOver: {
    fontSize: typography.fontSizes.xs,
    color: '#e65100',
    fontWeight: typography.fontWeights.medium,
  },
  rateComparison: {
    flexDirection: 'row',
    gap: spacing[4],
    marginBottom: spacing[2],
  },
  rateCol: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: spacing[2],
    backgroundColor: colors.white,
    borderRadius: borderRadius.md,
  },
  rateLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
  },
  rateAmount: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
    marginTop: 2,
  },
  rateSuggestion: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[600],
    fontStyle: 'italic',
  },

  // Insurance bundling
  bundleHint: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
    lineHeight: 20,
  },

  // Subscriptions
  subRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[50],
  },
  subName: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.slate[700],
  },
  subFreq: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginRight: spacing[3],
  },
  subAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    width: 60,
    textAlign: 'right',
  },
  moreText: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    textAlign: 'center',
    paddingTop: spacing[2],
  },

  // No savings
  noSavingsCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[6],
    alignItems: 'center',
    ...shadows.sm,
  },
  noSavingsTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginTop: spacing[3],
  },
  noSavingsText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    textAlign: 'center',
    marginTop: spacing[2],
    maxWidth: 280,
    lineHeight: 20,
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
