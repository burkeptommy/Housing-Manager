import { useState, useEffect, useCallback, useMemo } from 'react';
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
import { DonutChart } from '../../../src/components/charts';
import { successNotification, selectionChanged } from '../../../src/lib/haptics';

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

interface BudgetSuggestion {
  categoryId: string;
  groupId: string;
  name: string;
  icon: string;
  suggestedAmount: number;
  threeMonthAvg: number;
  reason: string;
}

interface SuggestionsData {
  hasBudget: boolean;
  monthlyIncome: number;
  suggestions: BudgetSuggestion[];
  totalSuggested: number;
  maintenanceReserve: number;
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
  const [spending, setSpending] = useState<SpendingGroup[]>([]);
  const [suggestions, setSuggestions] = useState<SuggestionsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set());
  const [editingCategory, setEditingCategory] = useState<string | null>(null);
  const [editAmount, setEditAmount] = useState('');
  const [applyingAll, setApplyingAll] = useState(false);
  const [hasBudget, setHasBudget] = useState(false);
  const [monthlyIncome, setMonthlyIncome] = useState(0);

  const fetchData = useCallback(async () => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const [budgetRes, spendingRes, suggestRes] = await Promise.all([
        fetch(`${API_BASE_URL}/budgeting/budget`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/budgeting/spending/by-category`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/budgeting/budget/suggestions`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (budgetRes.ok) {
        const bData = await budgetRes.json();
        setHasBudget(bData.exists);
        setMonthlyIncome(bData.monthlyIncome || 0);
      }
      if (spendingRes.ok) setSpending(await spendingRes.json());
      if (suggestRes.ok) setSuggestions(await suggestRes.json());
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
    selectionChanged();
    setExpandedGroups((prev) => {
      const next = new Set(prev);
      if (next.has(groupId)) next.delete(groupId);
      else next.add(groupId);
      return next;
    });
  };

  const saveCategoryBudget = async (categoryId: string, amount: number) => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const response = await fetch(`${API_BASE_URL}/budgeting/budget/category/${categoryId}`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ budgetedAmount: amount }),
      });

      if (!response.ok) {
        throw new Error('Failed to update budget');
      }

      setEditingCategory(null);
      setEditAmount('');
      await fetchData();
    } catch (err) {
      Alert.alert('Error', 'Failed to update budget');
    }
  };

  const applyAllSuggestions = async () => {
    if (!suggestions) return;
    setApplyingAll(true);
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const categories = suggestions.suggestions.map((s) => ({
        categoryId: s.categoryId,
        groupId: s.groupId,
        budgetedAmount: s.suggestedAmount,
      }));

      const response = await fetch(`${API_BASE_URL}/budgeting/budget`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          monthlyIncome: suggestions.monthlyIncome || undefined,
          categories,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to apply budget suggestions');
      }

      successNotification();
      Alert.alert('Budget Created', 'AI suggestions have been applied to your budget.');
      await fetchData();
    } catch (err) {
      Alert.alert('Error', 'Failed to apply suggestions');
    } finally {
      setApplyingAll(false);
    }
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
      build: 'build-outline',
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
          <ActivityIndicator size="large" color={colors.haven.purple[500]} />
        </View>
      ) : (
        <View style={styles.content}>
          {/* AI Suggestions for new users */}
          {!hasBudget && suggestions && suggestions.suggestions.length > 0 && (
            <View style={styles.suggestSection}>
              <View style={styles.suggestHeader}>
                <Ionicons name="sparkles-outline" size={20} color={colors.haven.purple[600]} />
                <Text style={styles.suggestTitle}>AI Budget Suggestions</Text>
              </View>
              <Text style={styles.suggestSubtext}>
                Based on your spending history and household profile
              </Text>

              {suggestions.suggestions.slice(0, 8).map((s) => (
                <View key={s.categoryId} style={styles.suggestRow}>
                  <Ionicons name={getIonIcon(s.icon)} size={18} color={colors.haven.purple[500]} />
                  <View style={styles.suggestInfo}>
                    <Text style={styles.suggestName}>{s.name}</Text>
                    <Text style={styles.suggestReason}>{s.reason}</Text>
                  </View>
                  <Text style={styles.suggestAmount}>{formatCurrency(s.suggestedAmount)}</Text>
                </View>
              ))}

              {suggestions.maintenanceReserve > 0 && (
                <View style={styles.maintenanceRow}>
                  <Ionicons name="home-outline" size={16} color="#E65100" />
                  <Text style={styles.maintenanceText}>
                    Includes {formatCurrency(suggestions.maintenanceReserve)}/mo home maintenance reserve
                  </Text>
                </View>
              )}

              <View style={styles.suggestFooter}>
                <Text style={styles.suggestTotal}>
                  Total: {formatCurrency(suggestions.totalSuggested)}/mo
                </Text>
                <TouchableOpacity
                  style={styles.applyButton}
                  onPress={applyAllSuggestions}
                  disabled={applyingAll}
                >
                  <Text style={styles.applyButtonText}>
                    {applyingAll ? 'Applying...' : 'Apply All'}
                  </Text>
                </TouchableOpacity>
              </View>
            </View>
          )}

          {/* Monthly Income */}
          {monthlyIncome > 0 && (
            <View style={styles.incomeCard}>
              <Text style={styles.incomeLabel}>Monthly Income</Text>
              <Text style={styles.incomeAmount}>{formatCurrency(monthlyIncome)}</Text>
            </View>
          )}

          {/* Donut Chart Overview */}
          {spending.length > 0 && spending.some((g) => g.spent > 0) && (
            <View style={styles.donutSection}>
              <DonutChart
                segments={spending
                  .filter((g) => g.spent > 0)
                  .map((g) => ({ value: g.spent, color: g.color, label: g.name }))}
                size={160}
                strokeWidth={14}
                centerValue={formatCurrency(spending.reduce((s, g) => s + g.spent, 0))}
                centerLabel="Spent"
              />
              <View style={styles.donutLegend}>
                {spending
                  .filter((g) => g.spent > 0)
                  .slice(0, 6)
                  .map((g) => (
                    <View key={g.groupId} style={styles.legendItem}>
                      <View style={[styles.legendDot, { backgroundColor: g.color }]} />
                      <Text style={styles.legendLabel} numberOfLines={1}>{g.name}</Text>
                    </View>
                  ))}
              </View>
            </View>
          )}

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
                        <Ionicons name={getIonIcon(group.icon)} size={20} color={group.color} />
                      </View>
                      <View style={styles.groupInfo}>
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
                        <Text style={styles.groupBudgeted}>/ {formatCurrency(group.budgeted)}</Text>
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
                        const isEditing = editingCategory === cat.categoryId;
                        const avg = suggestions?.suggestions.find(
                          (s) => s.categoryId === cat.categoryId,
                        )?.threeMonthAvg;

                        return (
                          <View key={cat.categoryId}>
                            <TouchableOpacity
                              style={styles.categoryItem}
                              onPress={() => {
                                if (hasBudget) {
                                  setEditingCategory(cat.categoryId);
                                  setEditAmount(cat.budgeted > 0 ? cat.budgeted.toString() : '');
                                }
                              }}
                            >
                              <Text style={styles.catName} numberOfLines={1}>{cat.name}</Text>
                              <View style={styles.catBar}>
                                <View
                                  style={[
                                    styles.catBarFill,
                                    { width: `${catPercent}%`, backgroundColor: group.color },
                                  ]}
                                />
                              </View>
                              <Text style={styles.catAmount}>{formatCurrency(cat.spent)}</Text>
                            </TouchableOpacity>
                            {avg !== undefined && avg > 0 && (
                              <Text style={styles.catAvg}>3-mo avg: {formatCurrency(avg)}</Text>
                            )}
                            {isEditing && (
                              <View style={styles.editRow}>
                                <Text style={styles.editLabel}>Budget:</Text>
                                <TextInput
                                  style={styles.editInput}
                                  value={editAmount}
                                  onChangeText={setEditAmount}
                                  keyboardType="numeric"
                                  placeholder="0"
                                  autoFocus
                                />
                                <TouchableOpacity
                                  style={styles.editSave}
                                  onPress={() => {
                                    const amt = parseFloat(editAmount);
                                    if (!isNaN(amt)) saveCategoryBudget(cat.categoryId, amt);
                                  }}
                                >
                                  <Text style={styles.editSaveText}>Save</Text>
                                </TouchableOpacity>
                                <TouchableOpacity
                                  onPress={() => { setEditingCategory(null); setEditAmount(''); }}
                                >
                                  <Ionicons name="close" size={20} color={colors.slate[400]} />
                                </TouchableOpacity>
                              </View>
                            )}
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

  // Donut Chart
  donutSection: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginBottom: spacing[4],
    gap: spacing[4],
    ...shadows.sm,
  },
  donutLegend: {
    flex: 1,
    gap: spacing[2],
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  legendDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  legendLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[600],
    flex: 1,
  },

  // Suggestions
  suggestSection: {
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginBottom: spacing[4],
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
  },
  suggestHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[1],
  },
  suggestTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[800],
  },
  suggestSubtext: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[600],
    marginBottom: spacing[3],
  },
  suggestRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    gap: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.haven.purple[100],
  },
  suggestInfo: { flex: 1 },
  suggestName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  suggestReason: {
    fontSize: 11,
    color: colors.haven.purple[600],
    marginTop: 1,
  },
  suggestAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[700],
  },
  maintenanceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: spacing[3],
    paddingTop: spacing[2],
    borderTopWidth: 1,
    borderTopColor: colors.haven.purple[200],
  },
  maintenanceText: {
    fontSize: typography.fontSizes.xs,
    color: '#E65100',
    flex: 1,
  },
  suggestFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing[4],
  },
  suggestTotal: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.purple[800],
  },
  applyButton: {
    backgroundColor: colors.haven.purple[600],
    paddingHorizontal: spacing[5],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
  },
  applyButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },

  // Income
  incomeCard: {
    backgroundColor: colors.haven.purple[800],
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    marginBottom: spacing[4],
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  incomeLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[200],
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
  groupInfo: { flex: 1 },
  groupName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginBottom: 4,
  },
  groupProgress: { width: 100 },
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
  groupOverBudget: { color: colors.status.error },
  groupBudgeted: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginLeft: 2,
  },

  // Category
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
  catAvg: {
    fontSize: 10,
    color: colors.slate[400],
    marginLeft: 103, // align with category name
    marginTop: -4,
    marginBottom: spacing[1],
  },
  editRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[2],
    paddingLeft: spacing[1],
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing[3],
    marginTop: spacing[1],
    marginBottom: spacing[2],
  },
  editLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
  },
  editInput: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
    borderBottomWidth: 1,
    borderBottomColor: colors.haven.purple[400],
    paddingVertical: 2,
    paddingHorizontal: spacing[2],
  },
  editSave: {
    backgroundColor: colors.haven.purple[500],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.md,
  },
  editSaveText: {
    fontSize: typography.fontSizes.xs,
    color: colors.white,
    fontWeight: typography.fontWeights.semibold,
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
