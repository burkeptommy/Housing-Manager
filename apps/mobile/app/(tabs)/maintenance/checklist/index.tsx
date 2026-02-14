import React, { useState, useCallback, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Stack } from 'expo-router';
import { askAlfred } from '../../../../src/lib/navigation';
import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useFocusEffect } from '@react-navigation/native';
import { Card, Badge, Button } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import {
  HOME_MAINTENANCE_CHECKLIST,
  CHECKLIST_CATEGORIES,
  FREQUENCY_LABELS,
  getItemsDueInMonth,
  type ChecklistItem,
  type ChecklistCategory,
} from '../../../../src/lib/checklists';

// =============================================================================
// TYPES
// =============================================================================

type FilterTab = 'due' | 'all' | 'completed';

interface CompletedItem {
  itemId: string;
  completedAt: string;
}

// =============================================================================
// STORAGE KEYS
// =============================================================================

const COMPLETED_ITEMS_KEY = 'haven_checklist_completed';

// =============================================================================
// CHECKLIST SCREEN
// =============================================================================

export default function ChecklistScreen() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState<FilterTab>('due');
  const [completedItems, setCompletedItems] = useState<CompletedItem[]>([]);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<ChecklistCategory | 'all'>('all');

  // Load completed items from storage
  const loadCompletedItems = useCallback(async () => {
    try {
      const stored = await AsyncStorage.getItem(COMPLETED_ITEMS_KEY);
      if (stored) {
        setCompletedItems(JSON.parse(stored));
      }
    } catch (error) {
      console.error('Failed to load completed items:', error);
    }
  }, []);

  // Save completed items to storage
  const saveCompletedItems = useCallback(async (items: CompletedItem[]) => {
    try {
      await AsyncStorage.setItem(COMPLETED_ITEMS_KEY, JSON.stringify(items));
    } catch (error) {
      console.error('Failed to save completed items:', error);
    }
  }, []);

  // Load on focus
  useFocusEffect(
    useCallback(() => {
      loadCompletedItems();
    }, [loadCompletedItems])
  );

  // Get current month items due
  const currentMonth = new Date().getMonth() + 1;
  const itemsDueThisMonth = useMemo(() => getItemsDueInMonth(currentMonth), [currentMonth]);

  // Check if item is completed (within frequency window)
  const isItemCompleted = useCallback(
    (item: ChecklistItem) => {
      const completed = completedItems.find(c => c.itemId === item.id);
      if (!completed) return false;

      const completedDate = new Date(completed.completedAt);
      const now = new Date();
      const daysSinceCompleted = Math.floor(
        (now.getTime() - completedDate.getTime()) / (1000 * 60 * 60 * 24)
      );

      // Check if still valid based on frequency
      switch (item.frequency) {
        case 'monthly':
          return daysSinceCompleted < 30;
        case 'quarterly':
          return daysSinceCompleted < 90;
        case 'semi-annual':
          return daysSinceCompleted < 180;
        case 'annual':
          return daysSinceCompleted < 365;
        default:
          return daysSinceCompleted < 365;
      }
    },
    [completedItems]
  );

  // Toggle item completion
  const toggleComplete = useCallback(
    async (itemId: string) => {
      let newCompleted: CompletedItem[];
      const existingIndex = completedItems.findIndex(c => c.itemId === itemId);

      if (existingIndex >= 0) {
        // Remove from completed
        newCompleted = completedItems.filter(c => c.itemId !== itemId);
      } else {
        // Add to completed
        newCompleted = [
          ...completedItems,
          { itemId, completedAt: new Date().toISOString() },
        ];
      }

      setCompletedItems(newCompleted);
      await saveCompletedItems(newCompleted);
    },
    [completedItems, saveCompletedItems]
  );

  // Filter items based on active tab
  const filteredItems = useMemo(() => {
    let items: ChecklistItem[] = [];

    switch (activeTab) {
      case 'due':
        items = itemsDueThisMonth.filter(item => !isItemCompleted(item));
        break;
      case 'completed':
        items = HOME_MAINTENANCE_CHECKLIST.filter(item => isItemCompleted(item));
        break;
      case 'all':
      default:
        items = HOME_MAINTENANCE_CHECKLIST;
        break;
    }

    // Filter by category if selected
    if (selectedCategory !== 'all') {
      items = items.filter(item => item.category === selectedCategory);
    }

    return items;
  }, [activeTab, itemsDueThisMonth, isItemCompleted, selectedCategory]);

  // Stats
  const stats = useMemo(() => {
    const dueItems = itemsDueThisMonth.filter(item => !isItemCompleted(item));
    const completedCount = HOME_MAINTENANCE_CHECKLIST.filter(item =>
      isItemCompleted(item)
    ).length;

    return {
      dueCount: dueItems.length,
      completedCount,
      totalCount: HOME_MAINTENANCE_CHECKLIST.length,
    };
  }, [itemsDueThisMonth, isItemCompleted]);

  const handleRefresh = useCallback(async () => {
    setIsRefreshing(true);
    await loadCompletedItems();
    setIsRefreshing(false);
  }, [loadCompletedItems]);

  const navigateToDetail = (item: ChecklistItem) => {
    router.push({
      pathname: '/(tabs)/maintenance/checklist/[id]',
      params: { id: item.id },
    } as any);
  };

  // =============================================================================
  // RENDER
  // =============================================================================

  const renderChecklistItem = ({ item }: { item: ChecklistItem }) => {
    const completed = isItemCompleted(item);
    const categoryInfo = CHECKLIST_CATEGORIES[item.category];

    return (
      <TouchableOpacity
        onPress={() => navigateToDetail(item)}
        activeOpacity={0.7}
      >
        <Card style={[styles.itemCard, completed && styles.itemCardCompleted]}>
          <View style={styles.itemHeader}>
            {/* Checkbox */}
            <TouchableOpacity
              style={[styles.checkbox, completed && styles.checkboxChecked]}
              onPress={() => toggleComplete(item.id)}
            >
              {completed && (
                <Ionicons name="checkmark" size={16} color={colors.white} />
              )}
            </TouchableOpacity>

            {/* Content */}
            <View style={styles.itemContent}>
              <Text
                style={[styles.itemTitle, completed && styles.itemTitleCompleted]}
              >
                {item.title}
              </Text>
              <Text style={styles.itemDescription} numberOfLines={2}>
                {item.description}
              </Text>

              {/* Meta info */}
              <View style={styles.itemMeta}>
                <Badge
                  label={categoryInfo.label}
                  variant="default"
                  size="sm"
                  style={{ backgroundColor: categoryInfo.color + '20' }}
                />
                <Text style={styles.itemFrequency}>
                  {FREQUENCY_LABELS[item.frequency]}
                </Text>
                {item.canHandymanDo && (
                  <View style={styles.handymanBadge}>
                    <Ionicons
                      name="hammer-outline"
                      size={12}
                      color={colors.haven.purple[500]}
                    />
                    <Text style={styles.handymanText}>Handyman</Text>
                  </View>
                )}
              </View>

              {/* Cost */}
              <View style={styles.costRow}>
                <Ionicons
                  name="cash-outline"
                  size={14}
                  color={colors.text.tertiary}
                />
                <Text style={styles.costText}>
                  {item.typicalCost.min === 0 && item.typicalCost.max === 0
                    ? 'Free'
                    : item.typicalCost.min === item.typicalCost.max
                    ? `$${item.typicalCost.min}`
                    : `$${item.typicalCost.min} - $${item.typicalCost.max}`}
                </Text>
              </View>
            </View>

            {/* Chevron */}
            <Ionicons
              name="chevron-forward"
              size={20}
              color={colors.text.tertiary}
            />
          </View>
        </Card>
      </TouchableOpacity>
    );
  };

  const renderCategoryFilter = () => (
    <View style={styles.categoryFilter}>
      <FlatList
        horizontal
        showsHorizontalScrollIndicator={false}
        data={[{ id: 'all' as const, label: 'All', icon: 'apps-outline' as const },
               ...Object.entries(CHECKLIST_CATEGORIES).map(([id, cat]) => ({
          id: id as ChecklistCategory,
          label: cat.label,
          icon: cat.icon,
        }))]}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.categoryFilterContent}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[
              styles.categoryChip,
              selectedCategory === item.id && styles.categoryChipSelected,
            ]}
            onPress={() => setSelectedCategory(item.id)}
          >
            <Ionicons
              name={item.icon as any}
              size={16}
              color={
                selectedCategory === item.id ? colors.white : colors.text.secondary
              }
            />
            <Text
              style={[
                styles.categoryChipText,
                selectedCategory === item.id && styles.categoryChipTextSelected,
              ]}
            >
              {item.label}
            </Text>
          </TouchableOpacity>
        )}
      />
    </View>
  );

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Home Maintenance',
          headerRight: () => (
            <TouchableOpacity
              style={styles.headerButton}
              onPress={() => router.push('/(tabs)/manager' as any)}
            >
              <Ionicons
                name="sparkles"
                size={24}
                color={colors.haven.purple[500]}
              />
            </TouchableOpacity>
          ),
        }}
      />

      {/* Stats Header */}
      <View style={styles.statsHeader}>
        <View style={styles.statItem}>
          <Text style={styles.statNumber}>{stats.dueCount}</Text>
          <Text style={styles.statLabel}>Due This Month</Text>
        </View>
        <View style={styles.statDivider} />
        <View style={styles.statItem}>
          <Text style={styles.statNumber}>{stats.completedCount}</Text>
          <Text style={styles.statLabel}>Completed</Text>
        </View>
        <View style={styles.statDivider} />
        <View style={styles.statItem}>
          <Text style={styles.statNumber}>{stats.totalCount}</Text>
          <Text style={styles.statLabel}>Total Items</Text>
        </View>
      </View>

      {/* Filter Tabs */}
      <View style={styles.tabContainer}>
        {(['due', 'all', 'completed'] as FilterTab[]).map(tab => (
          <TouchableOpacity
            key={tab}
            style={[styles.tab, activeTab === tab && styles.tabActive]}
            onPress={() => setActiveTab(tab)}
          >
            <Text
              style={[styles.tabText, activeTab === tab && styles.tabTextActive]}
            >
              {tab === 'due'
                ? `Due (${stats.dueCount})`
                : tab === 'completed'
                ? `Done (${stats.completedCount})`
                : 'All'}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Category Filter */}
      {renderCategoryFilter()}

      {/* Checklist Items */}
      <FlatList
        data={filteredItems}
        renderItem={renderChecklistItem}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={handleRefresh} />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons
              name={activeTab === 'completed' ? 'checkmark-circle' : 'checkbox-outline'}
              size={48}
              color={colors.haven.purple[300]}
            />
            <Text style={styles.emptyTitle}>
              {activeTab === 'due'
                ? 'All caught up!'
                : activeTab === 'completed'
                ? 'No completed items'
                : 'No items found'}
            </Text>
            <Text style={styles.emptyText}>
              {activeTab === 'due'
                ? 'No maintenance tasks due this month'
                : activeTab === 'completed'
                ? 'Complete tasks to see them here'
                : 'Try adjusting your filters'}
            </Text>
          </View>
        }
      />

      {/* Alfred CTA */}
      <View style={styles.alfredCTA}>
        <View style={styles.alfredIcon}>
          <Ionicons name="sparkles" size={20} color={colors.haven.purple[500]} />
        </View>
        <View style={styles.alfredContent}>
          <Text style={styles.alfredTitle}>Need help?</Text>
          <Text style={styles.alfredDescription}>
            Alfred can schedule any task or find trusted vendors
          </Text>
        </View>
        <Button
          title="Ask Alfred"
          variant="secondary"
          size="sm"
          onPress={() => askAlfred()}
          style={styles.alfredButton}
        />
      </View>
    </SafeAreaView>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  headerButton: {
    padding: spacing[2],
  },
  statsHeader: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
  },
  statNumber: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.purple[900],
  },
  statLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  statDivider: {
    width: 1,
    backgroundColor: colors.border.light,
    marginVertical: spacing[2],
  },
  tabContainer: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    paddingHorizontal: spacing[4],
    paddingBottom: spacing[3],
  },
  tab: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
    marginHorizontal: spacing[1],
  },
  tabActive: {
    backgroundColor: colors.haven.purple[900],
  },
  tabText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  tabTextActive: {
    color: colors.white,
  },
  categoryFilter: {
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  categoryFilterContent: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    gap: spacing[2],
  },
  categoryChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[1.5],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    backgroundColor: colors.background.tertiary,
    gap: spacing[1],
    marginRight: spacing[2],
  },
  categoryChipSelected: {
    backgroundColor: colors.haven.purple[500],
  },
  categoryChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  categoryChipTextSelected: {
    color: colors.white,
  },
  listContent: {
    padding: spacing[4],
    paddingBottom: spacing[24],
  },
  itemCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  itemCardCompleted: {
    opacity: 0.7,
    backgroundColor: colors.gray[50],
  },
  itemHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: colors.border.default,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
    marginTop: spacing[1],
  },
  checkboxChecked: {
    backgroundColor: colors.status.success,
    borderColor: colors.status.success,
  },
  itemContent: {
    flex: 1,
  },
  itemTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  itemTitleCompleted: {
    textDecorationLine: 'line-through',
    color: colors.text.tertiary,
  },
  itemDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
    marginBottom: spacing[2],
  },
  itemMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  itemFrequency: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  handymanBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    backgroundColor: colors.haven.purple[50],
    paddingHorizontal: spacing[2],
    paddingVertical: spacing[0.5],
    borderRadius: borderRadius.full,
  },
  handymanText: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  costRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  costText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing[10],
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
    marginTop: spacing[1],
    textAlign: 'center',
  },
  alfredCTA: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    shadowColor: colors.black,
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 4,
  },
  alfredIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  alfredContent: {
    flex: 1,
    marginLeft: spacing[3],
  },
  alfredTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  alfredDescription: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: spacing[0.5],
  },
  alfredButton: {
    minWidth: 90,
  },
});
