import { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  Dimensions,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../src/components/ScreenContainer';
import { colors, spacing, typography, borderRadius, shadows } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

interface SpendingSummary {
  monthlyIncome: number | null;
  totalSpent: number;
  totalBudget: number;
  topCategories: Array<{
    categoryId: string;
    name: string;
    color: string;
    spent: number;
    budget: number | null;
  }>;
  upcomingBills: Array<{
    id: string;
    name: string;
    amount: number;
    dueDate: string;
  }>;
  forecastPreview: {
    upcomingCount: number;
    totalCost: number;
  } | null;
  insight: string | null;
}

function formatCurrency(amount: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

const screenWidth = Dimensions.get('window').width;

export default function MoneyOverview() {
  const router = useRouter();
  const [data, setData] = useState<SpendingSummary | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const res = await fetch(`${API_BASE_URL}/budgeting/spending/summary`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        setData(await res.json());
      }
    } catch (err) {
      console.error('Money overview error:', err);
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

  const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
  const spentPercent = data && data.totalBudget > 0
    ? Math.min((data.totalSpent / data.totalBudget) * 100, 100)
    : 0;
  const remaining = data ? data.totalBudget - data.totalSpent : 0;

  return (
    <ScreenContainer
      title="Money"
      showBack={false}
      refreshing={refreshing}
      onRefresh={onRefresh}
    >
      {isLoading ? (
        <View style={styles.loading}>
          <ActivityIndicator size="large" color={colors.haven.sage[500]} />
        </View>
      ) : (
        <View style={styles.content}>
          {/* Hero Summary Card */}
          <View style={styles.heroCard}>
            <Text style={styles.heroLabel}>{currentMonth}</Text>
            <Text style={styles.heroAmount}>
              {formatCurrency(data?.totalSpent || 0)}
            </Text>
            <Text style={styles.heroSubtext}>
              {data?.totalBudget
                ? `of ${formatCurrency(data.totalBudget)} budget`
                : 'spent this month'}
            </Text>

            {data?.totalBudget ? (
              <View style={styles.progressContainer}>
                <View style={styles.progressBar}>
                  <View
                    style={[
                      styles.progressFill,
                      {
                        width: `${spentPercent}%`,
                        backgroundColor:
                          spentPercent > 90
                            ? colors.status.error
                            : spentPercent > 75
                              ? colors.status.warning
                              : colors.haven.sage[500],
                      },
                    ]}
                  />
                </View>
                <Text style={styles.remainingText}>
                  {remaining >= 0
                    ? `${formatCurrency(remaining)} remaining`
                    : `${formatCurrency(Math.abs(remaining))} over budget`}
                </Text>
              </View>
            ) : null}
          </View>

          {/* Insight Banner */}
          {data?.insight && (
            <View style={styles.insightBanner}>
              <Ionicons name="bulb-outline" size={18} color={colors.haven.sage[600]} />
              <Text style={styles.insightText}>{data.insight}</Text>
            </View>
          )}

          {/* Quick Nav Cards */}
          <View style={styles.navGrid}>
            <TouchableOpacity
              style={styles.navCard}
              onPress={() => router.push('/money/budget' as any)}
              activeOpacity={0.7}
            >
              <View style={[styles.navIcon, { backgroundColor: colors.haven.sage[100] }]}>
                <Ionicons name="pie-chart-outline" size={22} color={colors.haven.sage[600]} />
              </View>
              <Text style={styles.navTitle}>Budget</Text>
              <Text style={styles.navSubtitle}>Set & track</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.navCard}
              onPress={() => router.push('/money/transactions' as any)}
              activeOpacity={0.7}
            >
              <View style={[styles.navIcon, { backgroundColor: colors.haven.navy[100] }]}>
                <Ionicons name="list-outline" size={22} color={colors.haven.navy[600]} />
              </View>
              <Text style={styles.navTitle}>Transactions</Text>
              <Text style={styles.navSubtitle}>Recent activity</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.navCard}
              onPress={() => router.push('/money/forecast' as any)}
              activeOpacity={0.7}
            >
              <View style={[styles.navIcon, { backgroundColor: '#FFF3E0' }]}>
                <Ionicons name="trending-up-outline" size={22} color="#E65100" />
              </View>
              <Text style={styles.navTitle}>Forecast</Text>
              <Text style={styles.navSubtitle}>Home costs</Text>
            </TouchableOpacity>
          </View>

          {/* Top Spending Categories */}
          {data?.topCategories && data.topCategories.length > 0 && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>Top Spending</Text>
                <TouchableOpacity onPress={() => router.push('/money/budget' as any)}>
                  <Text style={styles.sectionLink}>See All</Text>
                </TouchableOpacity>
              </View>
              {data.topCategories.slice(0, 4).map((cat) => (
                <View key={cat.categoryId} style={styles.categoryRow}>
                  <View style={[styles.categoryDot, { backgroundColor: cat.color }]} />
                  <Text style={styles.categoryName} numberOfLines={1}>
                    {cat.name}
                  </Text>
                  <View style={styles.categoryAmounts}>
                    <Text style={styles.categorySpent}>{formatCurrency(cat.spent)}</Text>
                    {cat.budget ? (
                      <Text style={styles.categoryBudget}>
                        / {formatCurrency(cat.budget)}
                      </Text>
                    ) : null}
                  </View>
                </View>
              ))}
            </View>
          )}

          {/* Upcoming Bills */}
          {data?.upcomingBills && data.upcomingBills.length > 0 && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>Upcoming Bills</Text>
              </View>
              {data.upcomingBills.map((bill) => (
                <View key={bill.id} style={styles.billRow}>
                  <View style={styles.billIcon}>
                    <Ionicons name="calendar-outline" size={18} color={colors.haven.navy[500]} />
                  </View>
                  <View style={styles.billInfo}>
                    <Text style={styles.billName}>{bill.name}</Text>
                    <Text style={styles.billDue}>{bill.dueDate}</Text>
                  </View>
                  <Text style={styles.billAmount}>{formatCurrency(bill.amount)}</Text>
                </View>
              ))}
            </View>
          )}

          {/* Home Forecast Preview */}
          {data?.forecastPreview && (
            <TouchableOpacity
              style={styles.forecastCard}
              onPress={() => router.push('/money/forecast' as any)}
              activeOpacity={0.7}
            >
              <View style={styles.forecastIcon}>
                <Ionicons name="home-outline" size={24} color={colors.haven.navy[700]} />
              </View>
              <View style={styles.forecastContent}>
                <Text style={styles.forecastTitle}>Home Forecast</Text>
                <Text style={styles.forecastSubtext}>
                  {data.forecastPreview.upcomingCount} system{data.forecastPreview.upcomingCount !== 1 ? 's' : ''} need
                  attention in the next 5 years
                </Text>
                <Text style={styles.forecastCost}>
                  Est. {formatCurrency(data.forecastPreview.totalCost)}
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.slate[400]} />
            </TouchableOpacity>
          )}

          {/* Empty state if no data */}
          {!data?.totalBudget && !data?.topCategories?.length && (
            <View style={styles.emptyState}>
              <Ionicons name="wallet-outline" size={48} color={colors.slate[300]} />
              <Text style={styles.emptyTitle}>Set Up Your Budget</Text>
              <Text style={styles.emptySubtext}>
                Track spending, set goals, and forecast home costs all in one place.
              </Text>
              <TouchableOpacity
                style={styles.setupButton}
                onPress={() => router.push('/money/budget' as any)}
              >
                <Text style={styles.setupButtonText}>Get Started</Text>
              </TouchableOpacity>
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

  // Hero Card
  heroCard: {
    backgroundColor: colors.haven.navy[800],
    borderRadius: borderRadius.xl,
    padding: spacing[6],
    marginBottom: spacing[4],
  },
  heroLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.sage[200],
    marginBottom: spacing[1],
  },
  heroAmount: {
    fontSize: 40,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },
  heroSubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.sage[200],
    marginTop: spacing[1],
  },
  progressContainer: {
    marginTop: spacing[4],
  },
  progressBar: {
    height: 8,
    backgroundColor: 'rgba(255,255,255,0.15)',
    borderRadius: borderRadius.full,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: borderRadius.full,
  },
  remainingText: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.sage[200],
    marginTop: spacing[2],
  },

  // Insight
  insightBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    backgroundColor: colors.haven.sage[50],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    marginBottom: spacing[4],
    borderWidth: 1,
    borderColor: colors.haven.sage[200],
  },
  insightText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.sage[800],
    lineHeight: 20,
  },

  // Nav Grid
  navGrid: {
    flexDirection: 'row',
    gap: spacing[3],
    marginBottom: spacing[6],
  },
  navCard: {
    flex: 1,
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    alignItems: 'center',
    ...shadows.sm,
  },
  navIcon: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  navTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  navSubtitle: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
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
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  sectionLink: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.sage[500],
    fontWeight: typography.fontWeights.medium,
  },

  // Category rows
  categoryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
  },
  categoryDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    marginRight: spacing[3],
  },
  categoryName: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.slate[700],
  },
  categoryAmounts: {
    flexDirection: 'row',
    alignItems: 'baseline',
  },
  categorySpent: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  categoryBudget: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginLeft: 2,
  },

  // Bill rows
  billRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    gap: spacing[3],
  },
  billIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.navy[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  billInfo: {
    flex: 1,
  },
  billName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  billDue: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  billAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },

  // Forecast card
  forecastCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginBottom: spacing[4],
    gap: spacing[3],
    ...shadows.sm,
  },
  forecastIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.navy[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  forecastContent: {
    flex: 1,
  },
  forecastTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  forecastSubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  forecastCost: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.status.warning,
    marginTop: 4,
  },

  // Empty state
  emptyState: {
    alignItems: 'center',
    paddingVertical: spacing[12],
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
  setupButton: {
    backgroundColor: colors.haven.sage[500],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
    marginTop: spacing[6],
  },
  setupButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
});
