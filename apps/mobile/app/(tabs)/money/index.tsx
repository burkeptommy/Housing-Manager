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
import { useAuth } from '../../../src/contexts/auth-context';
import { usePlaid } from '../../../src/contexts/plaid-context';
import { colors, spacing, typography, borderRadius, shadows } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';
import { SparklineChart } from '../../../src/components/charts';
import { MoneySkeleton } from '../../../src/components/ui/Skeleton';

interface EnhancedSummary {
  period: { month: string };
  spending: {
    totalSpent: number;
    totalBudget: number;
    remaining: number;
    monthlyIncome: number | null;
  };
  comparisons: {
    monthOverMonth: number;
    weekOverWeek: number;
  };
  pace: {
    dailyAverage: number;
    projectedTotal: number;
    onTrack: boolean;
    dayOfMonth: number;
    daysInMonth: number;
  };
  weeklyBreakdown: Array<{ week: number; amount: number }>;
  topCategories: Array<{
    categoryId: string;
    name: string;
    color: string;
    icon: string;
    spent: number;
    delta: number;
    trend: 'up' | 'down' | 'stable';
  }>;
  upcoming: Array<{
    id: string;
    name: string;
    amount: number;
    dueDate: string | null;
    type: 'bill' | 'maintenance';
    icon: string;
  }>;
  maintenance: {
    budgeted: number;
    spent: number;
    urgentCount: number;
  };
  insights: Array<{
    type: string;
    title: string;
    message: string;
    action?: string;
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
  if (!dateStr) return 'No date';
  const d = new Date(dateStr);
  const now = new Date();
  const diffDays = Math.ceil((d.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Tomorrow';
  if (diffDays < 7) return `In ${diffDays} days`;
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export default function MoneyOverview() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const { connectBank } = usePlaid();
  const [data, setData] = useState<EnhancedSummary | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const res = await fetch(`${API_BASE_URL}/budgeting/spending/enhanced-summary`, {
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

  const spentPercent = data && data.spending.totalBudget > 0
    ? Math.min((data.spending.totalSpent / data.spending.totalBudget) * 100, 100)
    : 0;

  return (
    <ScreenContainer
      title="Money"
      showBack={false}
      refreshing={refreshing}
      onRefresh={onRefresh}
    >
      {isLoading ? (
        <MoneySkeleton />
      ) : (
        <View style={styles.content}>
          {/* Hero Card */}
          <View style={styles.heroCard}>
            <Text style={styles.heroLabel}>{data?.period.month || 'This Month'}</Text>
            <View style={styles.heroRow}>
              <Text style={styles.heroAmount}>
                {formatCurrency(data?.spending.totalSpent || 0)}
              </Text>
              {data && data.comparisons.monthOverMonth !== 0 && (
                <View style={[
                  styles.compBadge,
                  data.comparisons.monthOverMonth > 0 ? styles.compBadgeUp : styles.compBadgeDown,
                ]}>
                  <Ionicons
                    name={data.comparisons.monthOverMonth > 0 ? 'arrow-up' : 'arrow-down'}
                    size={12}
                    color={data.comparisons.monthOverMonth > 0 ? colors.status.error : colors.status.success}
                  />
                  <Text style={[
                    styles.compBadgeText,
                    data.comparisons.monthOverMonth > 0 ? styles.compTextUp : styles.compTextDown,
                  ]}>
                    {Math.abs(data.comparisons.monthOverMonth)}%
                  </Text>
                </View>
              )}
            </View>
            <Text style={styles.heroSubtext}>
              {data?.spending.totalBudget
                ? `of ${formatCurrency(data.spending.totalBudget)} budget`
                : 'spent this month'}
            </Text>

            {data?.spending.totalBudget ? (
              <View style={styles.progressContainer}>
                <View style={styles.progressBar}>
                  <View
                    style={[
                      styles.progressFill,
                      {
                        width: `${spentPercent}%`,
                        backgroundColor: spentPercent > 90
                          ? colors.status.error
                          : spentPercent > 75
                            ? colors.status.warning
                            : colors.haven.purple[400],
                      },
                    ]}
                  />
                </View>
                <Text style={styles.remainingText}>
                  {data.spending.remaining >= 0
                    ? `${formatCurrency(data.spending.remaining)} remaining`
                    : `${formatCurrency(Math.abs(data.spending.remaining))} over budget`}
                </Text>
              </View>
            ) : null}

            {/* Spending Pace */}
            {data?.pace && data.pace.dailyAverage > 0 && (
              <View style={styles.paceRow}>
                <Ionicons
                  name={data.pace.onTrack ? 'checkmark-circle' : 'alert-circle'}
                  size={14}
                  color={data.pace.onTrack ? '#4ade80' : '#fbbf24'}
                />
                <Text style={styles.paceText}>
                  {formatCurrency(data.pace.dailyAverage)}/day
                  {data.spending.totalBudget > 0 && (data.pace.onTrack ? ' — on track' : ' — over pace')}
                </Text>
              </View>
            )}

            {/* Weekly Sparkline */}
            {data?.weeklyBreakdown && data.weeklyBreakdown.length > 1 && (
              <View style={styles.sparklineContainer}>
                <SparklineChart
                  data={data.weeklyBreakdown.map((w) => w.amount)}
                  width={Dimensions.get('window').width - spacing[4] * 2 - spacing[6] * 2}
                  height={50}
                  color="rgba(255,255,255,0.8)"
                  fillOpacity={0.2}
                  strokeWidth={2}
                />
              </View>
            )}
          </View>

          {/* Quick Stats Row */}
          <View style={styles.statsRow}>
            <TouchableOpacity
              style={styles.statPill}
              onPress={() => router.push('/money/recurring' as any)}
            >
              <Ionicons name="repeat-outline" size={14} color={colors.haven.purple[600]} />
              <Text style={styles.statPillText}>Recurring</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.statPill}
              onPress={() => router.push('/money/budget' as any)}
            >
              <Ionicons name="pie-chart-outline" size={14} color={colors.haven.purple[600]} />
              <Text style={styles.statPillText}>Budget</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.statPill}
              onPress={() => router.push('/money/forecast' as any)}
            >
              <Ionicons name="home-outline" size={14} color={colors.haven.purple[600]} />
              <Text style={styles.statPillText}>
                Home{data?.maintenance.urgentCount ? ` (${data.maintenance.urgentCount})` : ''}
              </Text>
            </TouchableOpacity>
          </View>

          {/* Insight Banners */}
          {data?.insights && data.insights.length > 0 && (
            <View style={styles.insightsSection}>
              {data.insights.slice(0, 2).map((insight, i) => (
                <TouchableOpacity
                  key={i}
                  style={[
                    styles.insightBanner,
                    insight.type === 'overspend' && styles.insightWarning,
                    insight.type === 'forecast' && styles.insightAlert,
                    insight.type === 'setup' && styles.insightInfo,
                  ]}
                  onPress={() => {
                    if (insight.action === 'Review Budget' || insight.action === 'Set Up Budget') {
                      router.push('/money/budget' as any);
                    } else if (insight.action === 'View Transactions') {
                      router.push('/money/transactions' as any);
                    } else if (insight.action === 'View Forecast') {
                      router.push('/money/forecast' as any);
                    }
                  }}
                >
                  <Ionicons
                    name={
                      insight.type === 'overspend' ? 'trending-up' :
                      insight.type === 'pace' ? 'speedometer-outline' :
                      insight.type === 'forecast' ? 'home-outline' :
                      'bulb-outline'
                    }
                    size={18}
                    color={
                      insight.type === 'overspend' ? colors.status.error :
                      insight.type === 'forecast' ? '#E65100' :
                      colors.haven.purple[600]
                    }
                  />
                  <View style={styles.insightContent}>
                    <Text style={styles.insightTitle}>{insight.title}</Text>
                    <Text style={styles.insightMessage}>{insight.message}</Text>
                  </View>
                  {insight.action && (
                    <Ionicons name="chevron-forward" size={16} color={colors.slate[400]} />
                  )}
                </TouchableOpacity>
              ))}
            </View>
          )}

          {/* Upcoming Payments */}
          {data?.upcoming && data.upcoming.length > 0 && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>Upcoming</Text>
                <TouchableOpacity onPress={() => router.push('/money/recurring' as any)}>
                  <Text style={styles.sectionLink}>See All</Text>
                </TouchableOpacity>
              </View>
              {data.upcoming.slice(0, 5).map((item) => (
                <View key={item.id} style={styles.upcomingRow}>
                  <View style={[
                    styles.upcomingIcon,
                    item.type === 'maintenance' && styles.upcomingIconMaint,
                  ]}>
                    <Ionicons
                      name={(item.icon || 'card-outline') as any}
                      size={16}
                      color={item.type === 'maintenance' ? '#E65100' : colors.haven.purple[500]}
                    />
                  </View>
                  <View style={styles.upcomingInfo}>
                    <Text style={styles.upcomingName} numberOfLines={1}>{item.name}</Text>
                    <Text style={styles.upcomingDue}>{formatDueDate(item.dueDate)}</Text>
                  </View>
                  <Text style={styles.upcomingAmount}>
                    {item.amount > 0 ? formatCurrency(item.amount) : '—'}
                  </Text>
                </View>
              ))}
            </View>
          )}

          {/* Top Categories */}
          {data?.topCategories && data.topCategories.length > 0 && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>Top Spending</Text>
                <TouchableOpacity onPress={() => router.push('/money/budget' as any)}>
                  <Text style={styles.sectionLink}>Budget</Text>
                </TouchableOpacity>
              </View>
              {data.topCategories.slice(0, 5).map((cat) => (
                <View key={cat.categoryId} style={styles.categoryRow}>
                  <View style={[styles.categoryDot, { backgroundColor: cat.color }]} />
                  <Text style={styles.categoryName} numberOfLines={1}>{cat.name}</Text>
                  <View style={styles.categoryRight}>
                    <Text style={styles.categorySpent}>{formatCurrency(cat.spent)}</Text>
                    {cat.delta !== 0 && (
                      <View style={styles.deltaContainer}>
                        <Ionicons
                          name={cat.trend === 'up' ? 'caret-up' : 'caret-down'}
                          size={10}
                          color={cat.trend === 'up' ? colors.status.error : colors.status.success}
                        />
                        <Text style={[
                          styles.deltaText,
                          cat.trend === 'up' ? styles.deltaUp : styles.deltaDown,
                        ]}>
                          {Math.abs(cat.delta)}%
                        </Text>
                      </View>
                    )}
                  </View>
                </View>
              ))}
            </View>
          )}

          {/* Quick Nav */}
          <View style={styles.navGrid}>
            <TouchableOpacity
              style={styles.navCard}
              onPress={() => router.push('/money/transactions' as any)}
            >
              <Ionicons name="list-outline" size={22} color={colors.haven.purple[600]} />
              <Text style={styles.navTitle}>Transactions</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.navCard}
              onPress={() => router.push('/money/forecast' as any)}
            >
              <Ionicons name="trending-up-outline" size={22} color="#E65100" />
              <Text style={styles.navTitle}>Forecast</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.navCard}
              onPress={() => router.push('/money/insights' as any)}
            >
              <Ionicons name="bulb-outline" size={22} color="#2e7d32" />
              <Text style={styles.navTitle}>Savings</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.navCard}
              onPress={() => router.push('/money/recurring' as any)}
            >
              <Ionicons name="repeat-outline" size={22} color="#1565c0" />
              <Text style={styles.navTitle}>Recurring</Text>
            </TouchableOpacity>
          </View>

          {/* Empty state */}
          {!data?.spending.totalBudget && !data?.topCategories?.length && !data?.upcoming?.length && (
            <View style={styles.emptyState}>
              <Ionicons name="wallet-outline" size={48} color={colors.slate[300]} />
              <Text style={styles.emptyTitle}>Connect Your Bank</Text>
              <Text style={styles.emptySubtext}>
                Link your bank account to track spending, detect bills, and forecast home costs.
              </Text>
              <TouchableOpacity
                style={styles.setupButton}
                onPress={() => householdInfo?.id && connectBank(householdInfo.id)}
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

  // Sparkline
  sparklineContainer: {
    marginTop: spacing[3],
    alignItems: 'center',
    opacity: 0.9,
  },

  // Hero
  heroCard: {
    backgroundColor: colors.haven.purple[800],
    borderRadius: borderRadius.xl,
    padding: spacing[6],
    marginBottom: spacing[4],
  },
  heroLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[200],
    marginBottom: spacing[1],
  },
  heroRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
  },
  heroAmount: {
    fontSize: 40,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },
  heroSubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[200],
    marginTop: spacing[1],
  },
  compBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  compBadgeUp: {
    backgroundColor: 'rgba(239, 68, 68, 0.2)',
  },
  compBadgeDown: {
    backgroundColor: 'rgba(34, 197, 94, 0.2)',
  },
  compBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
  },
  compTextUp: { color: '#fca5a5' },
  compTextDown: { color: '#86efac' },
  progressContainer: { marginTop: spacing[4] },
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
    color: colors.haven.purple[200],
    marginTop: spacing[2],
  },
  paceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.1)',
  },
  paceText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[200],
  },

  // Stats Row
  statsRow: {
    flexDirection: 'row',
    gap: spacing[2],
    marginBottom: spacing[4],
  },
  statPill: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[1],
    backgroundColor: colors.haven.purple[50],
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[2],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
  },
  statPillText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[700],
  },

  // Insights
  insightsSection: {
    gap: spacing[2],
    marginBottom: spacing[4],
  },
  insightBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
  },
  insightWarning: {
    backgroundColor: '#FEF2F2',
    borderColor: '#FECACA',
  },
  insightAlert: {
    backgroundColor: '#FFF3E0',
    borderColor: '#FFE0B2',
  },
  insightInfo: {
    backgroundColor: colors.haven.purple[50],
    borderColor: colors.haven.purple[200],
  },
  insightContent: { flex: 1 },
  insightTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  insightMessage: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[600],
    marginTop: 2,
    lineHeight: 16,
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
    color: colors.haven.purple[500],
    fontWeight: typography.fontWeights.medium,
  },

  // Upcoming
  upcomingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    gap: spacing[3],
  },
  upcomingIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  upcomingIconMaint: {
    backgroundColor: '#FFF3E0',
  },
  upcomingInfo: { flex: 1 },
  upcomingName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  upcomingDue: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  upcomingAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },

  // Categories
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
  categoryRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  categorySpent: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  deltaContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 1,
  },
  deltaText: {
    fontSize: 10,
    fontWeight: typography.fontWeights.medium,
  },
  deltaUp: { color: colors.status.error },
  deltaDown: { color: colors.status.success },

  // Nav Grid
  navGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[3],
    marginBottom: spacing[4],
  },
  navCard: {
    width: '47%',
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    alignItems: 'center',
    gap: spacing[2],
    ...shadows.sm,
  },
  navTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
  },

  // Empty
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
    backgroundColor: colors.haven.purple[500],
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
