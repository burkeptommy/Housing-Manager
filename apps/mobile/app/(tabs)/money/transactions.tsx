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
  return Object.entries(groups).map(([date, items]) => ({
    date: formatDate(items[0].date),
    items,
  }));
}

export default function TransactionsScreen() {
  const router = useRouter();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const res = await fetch(`${API_BASE_URL}/budgeting/transactions?limit=100`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        setTransactions(await res.json());
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

  const grouped = groupByDate(transactions);

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
          <ActivityIndicator size="large" color={colors.haven.sage[500]} />
        </View>
      ) : transactions.length === 0 ? (
        <View style={styles.emptyState}>
          <Ionicons name="receipt-outline" size={48} color={colors.slate[300]} />
          <Text style={styles.emptyTitle}>No transactions yet</Text>
          <Text style={styles.emptySubtext}>
            Connect your bank account or add transactions manually to see them here.
          </Text>
        </View>
      ) : (
        <View style={styles.content}>
          {grouped.map((group) => (
            <View key={group.date} style={styles.dateGroup}>
              <Text style={styles.dateHeader}>{group.date}</Text>
              {group.items.map((t) => (
                <View key={t.id} style={styles.transactionRow}>
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
                          : (`${t.categoryIcon}-outline` as keyof typeof Ionicons.glyphMap)
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
                      {t.isPending ? ' - Pending' : ''}
                      {t.isRecurring ? ' - Recurring' : ''}
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
                </View>
              ))}
            </View>
          ))}
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
