import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { useRouter, useFocusEffect } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, LoadingSpinner, ScreenContainer } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface BudgetData {
  total: number;
  estimated: number;
  spentYTD: number;
  upcoming: number;
  byCategory: {
    category: string;
    estimated: number;
    spent: number;
    upcoming: number;
  }[];
  bySystem: {
    systemId: string;
    systemName: string;
    systemType: string;
    estimated: number;
    spent: number;
    upcoming: number;
  }[];
  upcomingTasks: {
    id: string;
    title: string;
    dueDate: string;
    estimatedCost: number;
    systemName: string;
  }[];
  monthlySpending: {
    month: string;
    amount: number;
  }[];
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
};

const getCategoryIcon = (category: string): string => {
  const iconMap: Record<string, string> = {
    HVAC: 'thermometer-outline',
    PLUMBING: 'water-outline',
    ELECTRICAL: 'flash-outline',
    EXTERIOR: 'home-outline',
    INTERIOR: 'cube-outline',
    APPLIANCES: 'hardware-chip-outline',
    POOL_SPA: 'water-outline',
    LANDSCAPING: 'leaf-outline',
    SAFETY: 'shield-outline',
    PEST_CONTROL: 'bug-outline',
    GENERAL: 'construct-outline',
  };
  return iconMap[category] || 'construct-outline';
};

// =============================================================================
// MAINTENANCE BUDGET SCREEN
// =============================================================================

export default function MaintenanceBudgetScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [budget, setBudget] = useState<BudgetData | null>(null);

  // =============================================================================
  // DATA FETCHING
  // =============================================================================

  const fetchBudget = useCallback(async () => {
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
        `${API_BASE_URL}/maintenance/budget/${householdInfo.id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        },
      );

      if (response.ok) {
        const data = await response.json();
        setBudget(data);
      }
    } catch (err) {
      console.error('Error fetching budget:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchBudget();
  }, [fetchBudget]);

  useFocusEffect(
    useCallback(() => {
      if (!isLoading) {
        fetchBudget();
      }
    }, [fetchBudget, isLoading]),
  );

  const handleRefresh = () => {
    setIsRefreshing(true);
    fetchBudget();
  };

  // =============================================================================
  // RENDER
  // =============================================================================

  if (isLoading) {
    return (
      <ScreenContainer title="Maintenance Budget" onBackPress={() => router.back()}>
        <View style={styles.loadingContainer}>
          <LoadingSpinner message="Loading budget..." />
        </View>
      </ScreenContainer>
    );
  }

  const currentYear = new Date().getFullYear();
  const progressPercent = budget
    ? Math.min((budget.spentYTD / budget.estimated) * 100, 100)
    : 0;

  return (
    <ScreenContainer title="Maintenance Budget" onBackPress={() => router.back()}>
      <ScrollView
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={handleRefresh} />
        }
        contentContainerStyle={styles.scrollContent}
      >
        {/* Annual Summary Card */}
        <Card style={styles.summaryCard}>
          <Text style={styles.summaryTitle}>{currentYear} Maintenance Budget</Text>
          <Text style={styles.summaryAmount}>
            {formatCurrency(budget?.estimated || 0)}
          </Text>
          <Text style={styles.summarySubtext}>
            Based on your home systems and industry averages
          </Text>

          {/* Progress Bar */}
          <View style={styles.progressContainer}>
            <View style={styles.progressBar}>
              <View
                style={[styles.progressFill, { width: `${progressPercent}%` }]}
              />
            </View>
            <View style={styles.progressLabels}>
              <Text style={styles.progressLabel}>
                {formatCurrency(budget?.spentYTD || 0)} spent
              </Text>
              <Text style={styles.progressLabel}>
                {formatCurrency((budget?.estimated || 0) - (budget?.spentYTD || 0))} remaining
              </Text>
            </View>
          </View>

          {/* Quick Stats */}
          <View style={styles.quickStats}>
            <View style={styles.quickStat}>
              <Text style={styles.quickStatLabel}>Spent YTD</Text>
              <Text style={styles.quickStatValue}>
                {formatCurrency(budget?.spentYTD || 0)}
              </Text>
            </View>
            <View style={styles.quickStatDivider} />
            <View style={styles.quickStat}>
              <Text style={styles.quickStatLabel}>Upcoming</Text>
              <Text style={styles.quickStatValue}>
                {formatCurrency(budget?.upcoming || 0)}
              </Text>
            </View>
          </View>
        </Card>

        {/* Breakdown by Category */}
        {budget?.byCategory && budget.byCategory.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>By Category</Text>
            {budget.byCategory.map((cat) => (
              <Card key={cat.category} style={styles.categoryCard}>
                <View style={styles.categoryHeader}>
                  <View style={styles.categoryIcon}>
                    <Ionicons
                      name={getCategoryIcon(cat.category) as any}
                      size={20}
                      color={colors.haven.purple[500]}
                    />
                  </View>
                  <View style={styles.categoryInfo}>
                    <Text style={styles.categoryName}>
                      {cat.category.replace(/_/g, ' ')}
                    </Text>
                    <Text style={styles.categoryEstimate}>
                      Est. {formatCurrency(cat.estimated)}
                    </Text>
                  </View>
                  <View style={styles.categoryAmounts}>
                    <Text style={styles.categorySpent}>
                      {formatCurrency(cat.spent)} spent
                    </Text>
                    {cat.upcoming > 0 && (
                      <Text style={styles.categoryUpcoming}>
                        +{formatCurrency(cat.upcoming)} upcoming
                      </Text>
                    )}
                  </View>
                </View>
              </Card>
            ))}
          </View>
        )}

        {/* Breakdown by System */}
        {budget?.bySystem && budget.bySystem.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>By System</Text>
            {budget.bySystem.map((sys) => (
              <TouchableOpacity
                key={sys.systemId}
                onPress={() => router.push(`/(tabs)/home/system/${sys.systemId}` as any)}
              >
                <Card style={styles.systemCard}>
                  <View style={styles.systemHeader}>
                    <View style={styles.systemInfo}>
                      <Text style={styles.systemName}>{sys.systemName}</Text>
                      <Text style={styles.systemType}>
                        {sys.systemType.replace(/_/g, ' ')}
                      </Text>
                    </View>
                    <View style={styles.systemAmounts}>
                      <Text style={styles.systemEstimate}>
                        {formatCurrency(sys.estimated)}/yr
                      </Text>
                      <Text style={styles.systemSpent}>
                        {formatCurrency(sys.spent)} spent
                      </Text>
                    </View>
                    <Ionicons
                      name="chevron-forward"
                      size={20}
                      color={colors.text.tertiary}
                    />
                  </View>
                </Card>
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* Upcoming Costs */}
        {budget?.upcomingTasks && budget.upcomingTasks.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Upcoming Maintenance Costs</Text>
            {budget.upcomingTasks.map((task) => (
              <TouchableOpacity
                key={task.id}
                onPress={() => router.push(`/(tabs)/maintenance/${task.id}` as any)}
              >
                <Card style={styles.upcomingCard}>
                  <View style={styles.upcomingInfo}>
                    <Text style={styles.upcomingTitle}>{task.title}</Text>
                    <Text style={styles.upcomingMeta}>
                      {task.systemName} • Due{' '}
                      {new Date(task.dueDate).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                      })}
                    </Text>
                  </View>
                  <Text style={styles.upcomingCost}>
                    {formatCurrency(task.estimatedCost)}
                  </Text>
                </Card>
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* Historical Spending Chart */}
        {budget?.monthlySpending && budget.monthlySpending.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Historical Spending</Text>
            <Card style={styles.chartCard}>
              <View style={styles.chartContainer}>
                {budget.monthlySpending.map((month, index) => {
                  const maxAmount = Math.max(
                    ...budget.monthlySpending.map((m) => m.amount),
                    1,
                  );
                  const height = (month.amount / maxAmount) * 100;

                  return (
                    <View key={month.month} style={styles.chartBar}>
                      <View style={styles.chartBarContainer}>
                        <View
                          style={[
                            styles.chartBarFill,
                            { height: `${Math.max(height, 5)}%` },
                          ]}
                        />
                      </View>
                      <Text style={styles.chartBarLabel}>
                        {month.month.substring(0, 3)}
                      </Text>
                    </View>
                  );
                })}
              </View>
              <View style={styles.chartLegend}>
                <Text style={styles.chartLegendText}>
                  Total:{' '}
                  {formatCurrency(
                    budget.monthlySpending.reduce((sum, m) => sum + m.amount, 0),
                  )}{' '}
                  over 12 months
                </Text>
              </View>
            </Card>
          </View>
        )}

        {/* Empty State */}
        {(!budget || budget.bySystem.length === 0) && (
          <View style={styles.emptyContainer}>
            <Ionicons
              name="calculator-outline"
              size={48}
              color={colors.haven.purple[300]}
            />
            <Text style={styles.emptyTitle}>No Budget Data Yet</Text>
            <Text style={styles.emptyText}>
              Add your home systems to see your estimated maintenance budget
            </Text>
            <TouchableOpacity
              style={styles.emptyButton}
              onPress={() => router.push('/(tabs)/home' as any)}
            >
              <Ionicons name="add-circle-outline" size={20} color={colors.white} />
              <Text style={styles.emptyButtonText}>Add Home Systems</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Spacer */}
        <View style={{ height: spacing[6] }} />
      </ScrollView>
    </ScreenContainer>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  scrollContent: {
    padding: spacing[4],
  },
  summaryCard: {
    padding: spacing[5],
    alignItems: 'center',
    backgroundColor: colors.haven.purple[900],
  },
  summaryTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[200],
  },
  summaryAmount: {
    fontSize: 40,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    marginTop: spacing[2],
  },
  summarySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[300],
    marginTop: spacing[1],
    textAlign: 'center',
  },
  progressContainer: {
    width: '100%',
    marginTop: spacing[5],
  },
  progressBar: {
    height: 8,
    backgroundColor: colors.haven.purple[700],
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.haven.purple[500],
    borderRadius: 4,
  },
  progressLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: spacing[2],
  },
  progressLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[300],
  },
  quickStats: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[5],
    paddingTop: spacing[4],
    borderTopWidth: 1,
    borderTopColor: colors.haven.purple[700],
    width: '100%',
  },
  quickStat: {
    flex: 1,
    alignItems: 'center',
  },
  quickStatLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[300],
  },
  quickStatValue: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    marginTop: spacing[1],
  },
  quickStatDivider: {
    width: 1,
    height: 40,
    backgroundColor: colors.haven.purple[700],
  },
  section: {
    marginTop: spacing[6],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[3],
  },
  categoryCard: {
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  categoryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  categoryIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  categoryInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  categoryName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    textTransform: 'capitalize',
  },
  categoryEstimate: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  categoryAmounts: {
    alignItems: 'flex-end',
  },
  categorySpent: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  categoryUpcoming: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[600],
    marginTop: spacing[0.5],
  },
  systemCard: {
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  systemHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  systemInfo: {
    flex: 1,
  },
  systemName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  systemType: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    textTransform: 'capitalize',
  },
  systemAmounts: {
    alignItems: 'flex-end',
    marginRight: spacing[2],
  },
  systemEstimate: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[600],
  },
  systemSpent: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  upcomingCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  upcomingInfo: {
    flex: 1,
  },
  upcomingTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  upcomingMeta: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: spacing[0.5],
  },
  upcomingCost: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[600],
  },
  chartCard: {
    padding: spacing[4],
  },
  chartContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    height: 120,
  },
  chartBar: {
    flex: 1,
    alignItems: 'center',
  },
  chartBarContainer: {
    width: 16,
    height: 100,
    backgroundColor: colors.haven.purple[100],
    borderRadius: 8,
    justifyContent: 'flex-end',
    overflow: 'hidden',
  },
  chartBarFill: {
    width: '100%',
    backgroundColor: colors.haven.purple[500],
    borderRadius: 8,
  },
  chartBarLabel: {
    fontSize: 10,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  chartLegend: {
    marginTop: spacing[3],
    alignItems: 'center',
  },
  chartLegendText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing[10],
    paddingHorizontal: spacing[6],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
    lineHeight: 20,
  },
  emptyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.purple[500],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[5],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
    gap: spacing[2],
  },
  emptyButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
});
