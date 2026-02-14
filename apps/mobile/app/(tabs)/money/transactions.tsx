import { useState, useEffect, useCallback, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  TextInput,
  Modal,
  FlatList,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../src/components/ScreenContainer';
import { colors, spacing, typography, borderRadius, shadows } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';
import { selectionChanged, successNotification } from '../../../src/lib/haptics';

interface Transaction {
  id: string;
  date: string;
  name: string;
  amount: number;
  categoryId: string | null;
  groupId: string | null;
  categoryName: string;
  categoryColor: string;
  categoryIcon: string;
  isPending: boolean;
  isRecurring: boolean;
  notes: string | null;
}

interface CategoryOption {
  id: string;
  name: string;
  groupId: string;
  color: string;
}

function formatCurrency(amount: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

function formatDate(dateStr: string) {
  const d = new Date(dateStr);
  const today = new Date();
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);

  if (d.toDateString() === today.toDateString()) return 'Today';
  if (d.toDateString() === yesterday.toDateString()) return 'Yesterday';
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function groupByDate(transactions: Transaction[]): Array<{ date: string; items: Transaction[] }> {
  const groups: Record<string, Transaction[]> = {};
  for (const t of transactions) {
    const key = new Date(t.date).toDateString();
    if (!groups[key]) groups[key] = [];
    groups[key].push(t);
  }
  return Object.entries(groups).map(([, items]) => ({
    date: formatDate(items[0].date),
    items,
  }));
}

const FILTER_CHIPS = [
  { id: 'all', label: 'All' },
  { id: 'recurring', label: 'Recurring' },
  { id: 'HOUSING', label: 'Housing' },
  { id: 'UTILITIES', label: 'Utilities' },
  { id: 'FOOD', label: 'Food' },
  { id: 'TRANSPORTATION', label: 'Transport' },
  { id: 'LIFESTYLE', label: 'Lifestyle' },
  { id: 'HEALTH', label: 'Health' },
  { id: 'SHOPPING', label: 'Shopping' },
];

export default function TransactionsScreen() {
  const router = useRouter();
  const [allTransactions, setAllTransactions] = useState<Transaction[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState('all');
  const [selectedTx, setSelectedTx] = useState<Transaction | null>(null);
  const [showCategoryPicker, setShowCategoryPicker] = useState(false);
  const [categories, setCategories] = useState<CategoryOption[]>([]);

  const fetchData = useCallback(async () => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const [txRes, budgetRes] = await Promise.all([
        fetch(`${API_BASE_URL}/budgeting/transactions?limit=200`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/budgeting/budget`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (txRes.ok) setAllTransactions(await txRes.json());
      if (budgetRes.ok) {
        const bData = await budgetRes.json();
        if (bData.categoryGroups) {
          const cats: CategoryOption[] = [];
          for (const [groupId, group] of Object.entries(bData.categoryGroups) as any) {
            for (const cat of group.categories) {
              cats.push({
                id: cat.id,
                name: cat.name,
                groupId,
                color: group.color,
              });
            }
          }
          setCategories(cats);
        }
      }
    } catch (err) {
      console.error('Transactions fetch error:', err);
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

  const filteredTransactions = useMemo(() => {
    let result = allTransactions;

    // Search filter
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter(
        (t) => t.name.toLowerCase().includes(q) || t.categoryName.toLowerCase().includes(q),
      );
    }

    // Category/type filter
    if (activeFilter === 'recurring') {
      result = result.filter((t) => t.isRecurring);
    } else if (activeFilter !== 'all') {
      result = result.filter((t) => t.groupId === activeFilter);
    }

    return result;
  }, [allTransactions, searchQuery, activeFilter]);

  const grouped = groupByDate(filteredTransactions);

  const recategorize = async (txId: string, categoryId: string, groupId: string) => {
    try {
      successNotification();
      const token = await getIdToken(true);
      if (!token) return;

      const response = await fetch(`${API_BASE_URL}/budgeting/transactions/${txId}/categorize`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ categoryId, groupId }),
      });

      if (!response.ok) {
        throw new Error('Failed to recategorize transaction');
      }

      setShowCategoryPicker(false);
      setSelectedTx(null);
      await fetchData();
    } catch (err) {
      console.error('Recategorize error:', err);
    }
  };

  return (
    <ScreenContainer
      title="Transactions"
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
          {/* Search Bar */}
          <View style={styles.searchBar}>
            <Ionicons name="search-outline" size={18} color={colors.slate[400]} />
            <TextInput
              style={styles.searchInput}
              placeholder="Search transactions..."
              placeholderTextColor={colors.slate[400]}
              value={searchQuery}
              onChangeText={setSearchQuery}
              autoCapitalize="none"
            />
            {searchQuery.length > 0 && (
              <TouchableOpacity onPress={() => setSearchQuery('')}>
                <Ionicons name="close-circle" size={18} color={colors.slate[400]} />
              </TouchableOpacity>
            )}
          </View>

          {/* Filter Chips */}
          <View style={styles.filterRow}>
            <FlatList
              horizontal
              showsHorizontalScrollIndicator={false}
              data={FILTER_CHIPS}
              keyExtractor={(item) => item.id}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={[
                    styles.filterChip,
                    activeFilter === item.id && styles.filterChipActive,
                  ]}
                  onPress={() => { selectionChanged(); setActiveFilter(item.id); }}
                >
                  <Text
                    style={[
                      styles.filterChipText,
                      activeFilter === item.id && styles.filterChipTextActive,
                    ]}
                  >
                    {item.label}
                  </Text>
                </TouchableOpacity>
              )}
              contentContainerStyle={styles.filterList}
            />
          </View>

          {/* Results */}
          {filteredTransactions.length === 0 ? (
            <View style={styles.emptyState}>
              <Ionicons name="receipt-outline" size={48} color={colors.slate[300]} />
              <Text style={styles.emptyTitle}>
                {searchQuery || activeFilter !== 'all' ? 'No matching transactions' : 'No transactions yet'}
              </Text>
              <Text style={styles.emptySubtext}>
                {searchQuery || activeFilter !== 'all'
                  ? 'Try a different search or filter.'
                  : 'Connect your bank account or add transactions manually.'}
              </Text>
            </View>
          ) : (
            grouped.map((group) => (
              <View key={group.date} style={styles.dateGroup}>
                <Text style={styles.dateHeader}>{group.date}</Text>
                {group.items.map((t) => (
                  <TouchableOpacity
                    key={t.id}
                    style={styles.transactionRow}
                    onPress={() => {
                      setSelectedTx(t);
                      setShowCategoryPicker(true);
                    }}
                    activeOpacity={0.7}
                  >
                    <View
                      style={[
                        styles.transactionIcon,
                        { backgroundColor: t.categoryColor + '20' },
                      ]}
                    >
                      <Ionicons
                        name={
                          t.categoryIcon === 'help'
                            ? 'help-circle-outline'
                            : (`${t.categoryIcon}-outline` as any)
                        }
                        size={18}
                        color={t.categoryColor}
                      />
                    </View>
                    <View style={styles.transactionInfo}>
                      <Text style={styles.transactionName} numberOfLines={1}>
                        {t.name}
                      </Text>
                      <Text style={styles.transactionCategory}>
                        {t.categoryName}
                        {t.isPending ? ' · Pending' : ''}
                        {t.isRecurring ? ' · Recurring' : ''}
                      </Text>
                    </View>
                    <Text
                      style={[
                        styles.transactionAmount,
                        t.amount < 0 && styles.incomeAmount,
                      ]}
                    >
                      {t.amount < 0 ? '+' : ''}{formatCurrency(Math.abs(t.amount))}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            ))
          )}
        </View>
      )}

      {/* Category Picker Modal */}
      <Modal
        visible={showCategoryPicker}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setShowCategoryPicker(false)}
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Change Category</Text>
            <TouchableOpacity onPress={() => setShowCategoryPicker(false)}>
              <Ionicons name="close" size={24} color={colors.slate[600]} />
            </TouchableOpacity>
          </View>
          {selectedTx && (
            <View style={styles.modalTxInfo}>
              <Text style={styles.modalTxName}>{selectedTx.name}</Text>
              <Text style={styles.modalTxAmount}>{formatCurrency(selectedTx.amount)}</Text>
            </View>
          )}
          <FlatList
            data={categories}
            keyExtractor={(item) => item.id}
            renderItem={({ item }) => (
              <TouchableOpacity
                style={[
                  styles.catOption,
                  selectedTx?.categoryId === item.id && styles.catOptionActive,
                ]}
                onPress={() => {
                  if (selectedTx) recategorize(selectedTx.id, item.id, item.groupId);
                }}
              >
                <View style={[styles.catOptionDot, { backgroundColor: item.color }]} />
                <Text style={styles.catOptionName}>{item.name}</Text>
                {selectedTx?.categoryId === item.id && (
                  <Ionicons name="checkmark" size={20} color={colors.haven.purple[500]} />
                )}
              </TouchableOpacity>
            )}
            contentContainerStyle={styles.catList}
          />
        </View>
      </Modal>
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

  // Search
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    marginBottom: spacing[3],
    gap: spacing[2],
    ...shadows.sm,
  },
  searchInput: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.slate[900],
    paddingVertical: spacing[1],
  },

  // Filters
  filterRow: {
    marginBottom: spacing[4],
  },
  filterList: {
    gap: spacing[2],
  },
  filterChip: {
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.slate[200],
  },
  filterChipActive: {
    backgroundColor: colors.haven.purple[500],
    borderColor: colors.haven.purple[500],
  },
  filterChipText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[600],
  },
  filterChipTextActive: {
    color: colors.white,
  },

  // Date groups
  dateGroup: {
    marginBottom: spacing[4],
  },
  dateHeader: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[500],
    marginBottom: spacing[2],
    paddingHorizontal: spacing[1],
  },

  // Transaction row
  transactionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    marginBottom: spacing[2],
    gap: spacing[3],
    ...shadows.sm,
  },
  transactionIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  transactionInfo: {
    flex: 1,
  },
  transactionName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  transactionCategory: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  transactionAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  incomeAmount: {
    color: colors.status.success,
  },

  // Modal
  modalContainer: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: spacing[4],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[100],
    backgroundColor: colors.white,
  },
  modalTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  modalTxInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: spacing[4],
    backgroundColor: colors.haven.purple[50],
  },
  modalTxName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  modalTxAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  catList: {
    padding: spacing[4],
  },
  catOption: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[4],
    gap: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[50],
  },
  catOptionActive: {
    backgroundColor: colors.haven.purple[50],
  },
  catOptionDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  catOptionName: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.slate[700],
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
