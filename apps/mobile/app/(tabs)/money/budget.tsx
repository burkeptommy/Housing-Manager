import { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  TextInput,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../src/components/ScreenContainer';
import { colors, spacing, typography, borderRadius, shadows } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

interface BudgetCategory {
  id: string;
  categoryId: string;
  groupId: string;
  budgetedAmount: number;
  name: string;
  groupName: string;
  color: string;
  icon: string;
}

interface CategoryGroup {
  name: string;
  icon: string;
  color: string;
  categories: Array<{ id: string; name: string; icon: string }>;
}

interface BudgetData {
  exists: boolean;
  id?: string;
  name?: string;
  monthlyIncome?: number;
  categories?: BudgetCategory[];
  categoryGroups: Record<string, CategoryGroup>;
  benchmarks: Record<string, { recommended: number; max: number; label: string }>;
}

interface SpendingGroup {
  groupId: string;
  name: string;
  color: string;
  icon: string;
  spent: number;
  budgeted: number;
  categories: Array<{
    categoryId: string;
    name: string;
    icon: string;
    spent: number;
    budgeted: number;
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

export default function BudgetScreen() {
  const router = useRouter();
  const [budget, setBudget] = useState<BudgetData | null>(null);
  const [spending, setSpending] = useState<SpendingGroup[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set());

  const fetchData = useCallback(async () => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const [budgetRes, spendingRes] = await Promise.all([
        fetch(`${API_BASE_URL}/budgeting/budget`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/budgeting/spending/by-category`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (budgetRes.ok) setBudget(await budgetRes.json());
      if (spendingRes.ok) setSpending(await spendingRes.json());
    } catch (err) {
      console.error('Budget fetch error:', err);
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

  const toggleGroup = (groupId: string) => {
    setExpandedGroups((prev) => {
      const next = new Set(prev);
      if (next.has(groupId)) next.delete(groupId);
      else next.add(groupId);
      return next;
    });
  };

  const getIonIcon = (icon: string): keyof typeof Ionicons.glyphMap => {
    const map: Record<string, keyof typeof Ionicons.glyphMap> = {
      home: 'home-outline',
      flash: 'flash-outline',
      restaurant: 'restaurant-outline',
      car: 'car-outline',
      heart: 'heart-outline',
      people: 'people-outline',
      paw: 'paw-outline',
      bag: 'bag-outline',
      airplane: 'airplane-outline',
      wallet: 'wallet-outline',
      gift: 'gift-outline',
      'trending-up': 'trending-up-outline',
      'ellipsis-horizontal': 'ellipsis-horizontal-outline',
    };
    return map[icon] || 'help-circle-outline';
  };

  return (
    <ScreenContainer
      title="Budget"
      showBack={true}
      onBackPress={() => router.back()}
      refreshing={refreshing}
      onRefresh={onRefresh}
    >
      {isLoading ? (
        <View style={styles.loading}>
          <ActivityIndicator size="large" color={colors.haven.sage[500]} />
        </View>
      ) : (
        <View style={styles.content}>
          {/* Monthly Income */}
          {budget?.monthlyIncome ? (
            <View style={styles.incomeCard}>
              <Text style={styles.incomeLabel}>Monthly Income</Text>
              <Text style={styles.incomeAmount}>
                {formatCurrency(budget.monthlyIncome)}
              </Text>
            </View>
          ) : null}

          {/* Spending by Group */}
          {spending.length > 0 ? (
            spending.map((group) => {
              const percent = group.budgeted > 0
                ? Math.min((group.spent / group.budgeted) * 100, 100)
                : 0;
              const isExpanded = expandedGroups.has(group.groupId);
              const isOver = group.budgeted > 0 && group.spent > group.budgeted;

              return (
                <View key={group.groupId} style={styles.groupCard}>
                  <TouchableOpacity
                    style={styles.groupHeader}
                    onPress={() => toggleGroup(group.groupId)}
                    activeOpacity={0.7}
                  >
                    <View style={styles.groupLeft}>
                      <View style={[styles.groupIcon, { backgroundColor: group.color + '20' }]}>
                        <Ionicons
                          name={getIonIcon(group.icon)}
                          size={20}
                          color={group.color}
                        />
                      </View>
                      <View>
                        <Text style={styles.groupName}>{group.name}</Text>
                        <View style={styles.groupProgress}>
                          <View style={styles.groupProgressBar}>
                            <View
                              style={[
                                styles.groupProgressFill,
                                {
                                  width: `${percent}%`,
                                  backgroundColor: isOver ? colors.status.error : group.color,
                                },
                              ]}
                            />
                          </View>
                        </View>
                      </View>
                    </View>
                    <View style={styles.groupRight}>
                      <Text style={[styles.groupSpent, isOver && styles.groupOverBudget]}>
                        {formatCurrency(group.spent)}
                      </Text>
                      {group.budgeted > 0 && (
                        <Text style={styles.groupBudgeted}>
                          / {formatCurrency(group.budgeted)}
                        </Text>
                      )}
                      <Ionicons
                        name={isExpanded ? 'chevron-up' : 'chevron-down'}
                        size={18}
                        color={colors.slate[400]}
                        style={{ marginLeft: spacing[2] }}
                      />
                    </View>
                  </TouchableOpacity>

                  {isExpanded && group.categories.length > 0 && (
                    <View style={styles.categoryList}>
                      {group.categories.map((cat) => {
                        const catPercent = cat.budgeted > 0
                          ? Math.min((cat.spent / cat.budgeted) * 100, 100)
                          : 0;
                        return (
                          <View key={cat.categoryId} style={styles.categoryItem}>
                            <Text style={styles.catName} numberOfLines={1}>
                              {cat.name}
                            </Text>
                            <View style={styles.catBar}>
                              <View
                                style={[
                                  styles.catBarFill,
                                  {
                                    width: `${catPercent}%`,
                                    backgroundColor: group.color,
                                  },
                                ]}
                              />
                            </View>
                            <Text style={styles.catAmount}>{formatCurrency(cat.spent)}</Text>
                          </View>
                        );
                      })}
                    </View>
                  )}
                </View>
              );
            })
          ) : (
            <View style={styles.emptyState}>
              <Ionicons name="pie-chart-outline" size={48} color={colors.slate[300]} />
              <Text style={styles.emptyTitle}>No spending data yet</Text>
              <Text style={styles.emptySubtext}>
                Connect your bank or add transactions to see your spending breakdown.
              </Text>
            </View>
          )}

          {/* Benchmarks */}
          {budget?.benchmarks && budget.monthlyIncome ? (
            <View style={styles.benchmarkSection}>
              <Text style={styles.benchmarkTitle}>Recommended Ranges</Text>
              <Text style={styles.benchmarkSubtext}>
                Based on ${formatCurrency(budget.monthlyIncome)}/mo income
              </Text>
              {Object.entries(budget.benchmarks).slice(0, 6).map(([groupId, bench]) => (
                <View key={groupId} style={styles.benchmarkRow}>
                  <Text style={styles.benchmarkName}>
                    {budget.categoryGroups[groupId]?.name || groupId}
                  </Text>
                  <Text style={styles.benchmarkRange}>{bench.label}</Text>
                </View>
              ))}
            </View>
          ) : null}
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

  // Income
  incomeCard: {
    backgroundColor: colors.haven.navy[800],
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    marginBottom: spacing[4],
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  incomeLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.sage[200],
  },
  incomeAmount: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },

  // Group card
  groupCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    marginBottom: spacing[3],
    overflow: 'hidden',
    ...shadows.sm,
  },
  groupHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
  },
  groupLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    flex: 1,
  },
  groupIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  groupName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginBottom: 4,
  },
  groupProgress: {
    width: 100,
  },
  groupProgressBar: {
    height: 4,
    backgroundColor: colors.slate[100],
    borderRadius: 2,
    overflow: 'hidden',
  },
  groupProgressFill: {
    height: '100%',
    borderRadius: 2,
  },
  groupRight: {
    flexDirection: 'row',
    alignItems: 'baseline',
  },
  groupSpent: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  groupOverBudget: {
    color: colors.status.error,
  },
  groupBudgeted: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginLeft: 2,
  },

  // Category list
  categoryList: {
    borderTopWidth: 1,
    borderTopColor: colors.slate[100],
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
  },
  categoryItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    gap: spacing[3],
  },
  catName: {
    width: 100,
    fontSize: typography.fontSizes.sm,
    color: colors.slate[700],
  },
  catBar: {
    flex: 1,
    height: 6,
    backgroundColor: colors.slate[100],
    borderRadius: 3,
    overflow: 'hidden',
  },
  catBarFill: {
    height: '100%',
    borderRadius: 3,
  },
  catAmount: {
    width: 60,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
    textAlign: 'right',
  },

  // Benchmarks
  benchmarkSection: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginTop: spacing[2],
    ...shadows.sm,
  },
  benchmarkTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  benchmarkSubtext: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
    marginBottom: spacing[3],
  },
  benchmarkRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[50],
  },
  benchmarkName: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[700],
  },
  benchmarkRange: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.sage[600],
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
});
