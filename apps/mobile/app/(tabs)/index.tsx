import { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  RefreshControl,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Link } from 'expo-router';
import { useAuth } from '../../src/contexts/auth-context';
import { getApiClient } from '../../src/lib/api';
import { colors, spacing, typography, borderRadius, shadows } from '../../src/lib/theme';
import type {
  DashboardResponse,
  UpcomingBill,
  UpcomingMaintenanceTask,
  TodayTask,
} from '@haven/core';

// Category icon mapping
const CATEGORY_ICONS: Record<string, string> = {
  // Vendor categories
  MORTGAGE: '🏠',
  HOA: '🏘️',
  PROPERTY_TAX: '📋',
  ELECTRIC: '⚡',
  GAS: '🔥',
  WATER_SEWER: '💧',
  TRASH: '🗑️',
  INTERNET: '🌐',
  MOBILE: '📱',
  CABLE: '📺',
  HOME_INSURANCE: '🛡️',
  AUTO_INSURANCE: '🚗',
  HEALTH_INSURANCE: '❤️',
  LIFE_INSURANCE: '💼',
  PET_INSURANCE: '🐾',
  CREDIT_CARD: '💳',
  STUDENT_LOAN: '🎓',
  PERSONAL_LOAN: '💰',
  VEHICLE_LOAN: '🚙',
  HELOC: '🏦',
  STREAMING: '🎬',
  GYM: '💪',
  SECURITY_MONITORING: '🔒',
  PEST_CONTROL: '🐛',
  LAWN_CARE: '🌱',
  LANDSCAPING: '🌳',
  HOME_WARRANTY: '📜',
  CLEANING: '🧹',
  WINDOW_WASHING: '🪟',
  GUTTER_CLEANING: '🍂',
  HVAC_SERVICE: '❄️',
  FILTER_SERVICE: '🌀',
  CHIMNEY_SWEEP: '🧱',
  SEPTIC_SERVICE: '🚽',
  POOL_SERVICE: '🏊',
  SNOW_REMOVAL: '❄️',
  HANDYMAN: '🔧',
  // Maintenance categories
  HVAC: '❄️',
  PLUMBING: '🔧',
  ROOF_GUTTER: '🏠',
  CHIMNEY: '🧱',
  SEPTIC: '🚽',
  PEST: '🐛',
  POOL: '🏊',
  SAFETY: '🛡️',
  APPLIANCES: '🔌',
  EXTERIOR: '🏡',
  INTERIOR: '🛋️',
  GENERAL: '🔨',
  OTHER: '📦',
};

function getCategoryIcon(category: string): string {
  return CATEGORY_ICONS[category] || '📋';
}

function formatCurrency(amount: number | undefined): string {
  if (amount === undefined) return '--';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(amount);
}

function formatDate(date: Date | string | undefined): string {
  if (!date) return '--';
  return new Date(date).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  });
}

function getDaysUntilLabel(days: number): string {
  if (days === 0) return 'Today';
  if (days === 1) return 'Tomorrow';
  if (days < 0) return `${Math.abs(days)} days overdue`;
  return `in ${days} days`;
}

export default function HomeScreen() {
  const { user, currentHousehold, refreshCurrentHousehold } = useAuth();
  const [dashboard, setDashboard] = useState<DashboardResponse | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const api = getApiClient();

  const fetchData = useCallback(async () => {
    if (!currentHousehold) return;

    try {
      const dashboardData = await api.getDashboard(currentHousehold.id);
      setDashboard(dashboardData);
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error);
    } finally {
      setIsLoading(false);
    }
  }, [api, currentHousehold]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await Promise.all([fetchData(), refreshCurrentHousehold()]);
    setRefreshing(false);
  }, [fetchData, refreshCurrentHousehold]);

  if (isLoading) {
    return (
      <SafeAreaView style={styles.loadingContainer} edges={['bottom']}>
        <ActivityIndicator size="large" color={colors.primary[600]} />
      </SafeAreaView>
    );
  }

  const summary = dashboard?.summary;
  const upcomingBills = dashboard?.upcomingBills || [];
  const upcomingMaintenanceTasks = dashboard?.upcomingMaintenanceTasks || [];

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={colors.primary[600]}
          />
        }
      >
        {/* Hero Summary Section */}
        <View style={styles.heroSection}>
          <Text style={styles.heroTitle}>Welcome back, {user?.firstName}!</Text>
          <Text style={styles.heroSubtitle}>
            This month: {summary?.billsManagedThisMonth || 0} bills managed,{' '}
            {summary?.tasksScheduledThisMonth || 0} tasks scheduled,{' '}
            {summary?.tasksCompletedThisMonth || 0} completed
          </Text>

          {/* Next Up Highlight */}
          {summary?.nextUp && (
            <View style={styles.nextUpCard}>
              <Text style={styles.nextUpLabel}>Next up</Text>
              <View style={styles.nextUpContent}>
                <Text style={styles.nextUpIcon}>{getCategoryIcon(summary.nextUp.category)}</Text>
                <View style={styles.nextUpDetails}>
                  <Text style={styles.nextUpTitle}>{summary.nextUp.title}</Text>
                  <Text style={styles.nextUpDue}>
                    {getDaysUntilLabel(summary.nextUp.daysUntilDue)}
                    {summary.nextUp.vendorName && ` with ${summary.nextUp.vendorName}`}
                  </Text>
                </View>
              </View>
            </View>
          )}
        </View>

        {/* Today's Tasks */}
        {summary?.todaysTasks && summary.todaysTasks.length > 0 && (
          <View style={styles.todaySection}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionIcon}>📅</Text>
              <Text style={styles.sectionTitle}>Today&apos;s Tasks</Text>
              <View style={styles.countBadge}>
                <Text style={styles.countBadgeText}>{summary.todaysTasks.length}</Text>
              </View>
            </View>
            {summary.todaysTasks.map((task: TodayTask) => (
              <View key={task.id} style={styles.todayTaskCard}>
                <Text style={styles.taskIcon}>{getCategoryIcon(task.category)}</Text>
                <View style={styles.taskContent}>
                  <Text style={styles.taskTitle}>{task.title}</Text>
                  {task.vendorName && (
                    <Text style={styles.taskVendor}>{task.vendorName}</Text>
                  )}
                </View>
                <View style={styles.taskRight}>
                  {task.amount !== undefined && (
                    <Text style={styles.taskAmount}>{formatCurrency(task.amount)}</Text>
                  )}
                  {task.scheduledTime && (
                    <Text style={styles.taskTime}>{task.scheduledTime}</Text>
                  )}
                </View>
              </View>
            ))}
          </View>
        )}

        {/* Upcoming Bills */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionIcon}>💰</Text>
            <Text style={styles.sectionTitle}>Upcoming Bills</Text>
            {upcomingBills.length > 0 && (
              <View style={[styles.countBadge, styles.blueBadge]}>
                <Text style={[styles.countBadgeText, styles.blueBadgeText]}>{upcomingBills.length}</Text>
              </View>
            )}
          </View>

          {upcomingBills.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyEmoji}>✨</Text>
              <Text style={styles.emptyText}>No upcoming bills in the next 30 days</Text>
            </View>
          ) : (
            upcomingBills.slice(0, 4).map((bill: UpcomingBill) => (
              <View
                key={bill.id}
                style={[styles.itemCard, bill.isOverdue && styles.overdueCard]}
              >
                <Text style={styles.itemIcon}>{getCategoryIcon(bill.category)}</Text>
                <View style={styles.itemContent}>
                  <Text style={styles.itemTitle}>{bill.nickname}</Text>
                  <Text style={styles.itemSubtitle}>{bill.vendorName}</Text>
                  <Text style={[styles.itemDue, bill.isOverdue && styles.overdueDue]}>
                    {formatDate(bill.nextDueDate)} ({getDaysUntilLabel(bill.daysUntilDue)})
                  </Text>
                </View>
                <View style={styles.itemRight}>
                  <Text style={styles.itemAmount}>{formatCurrency(bill.typicalAmount)}</Text>
                  {bill.paymentResponsibility === 'HAVEN_PAYS_ON_BEHALF' ? (
                    <Text style={styles.havenHandles}>✓ Haven handles</Text>
                  ) : (
                    <TouchableOpacity>
                      <Text style={styles.askHaven}>Ask Haven</Text>
                    </TouchableOpacity>
                  )}
                </View>
              </View>
            ))
          )}
        </View>

        {/* Upcoming Maintenance */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionIcon}>🔧</Text>
            <Text style={styles.sectionTitle}>Upcoming Maintenance</Text>
            {upcomingMaintenanceTasks.length > 0 && (
              <View style={[styles.countBadge, styles.purpleBadge]}>
                <Text style={[styles.countBadgeText, styles.purpleBadgeText]}>{upcomingMaintenanceTasks.length}</Text>
              </View>
            )}
          </View>

          {upcomingMaintenanceTasks.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyEmoji}>✨</Text>
              <Text style={styles.emptyText}>No upcoming maintenance tasks</Text>
            </View>
          ) : (
            upcomingMaintenanceTasks.slice(0, 4).map((task: UpcomingMaintenanceTask) => (
              <View
                key={task.id}
                style={[styles.itemCard, task.isOverdue && styles.overdueCard]}
              >
                <Text style={styles.itemIcon}>{getCategoryIcon(task.category)}</Text>
                <View style={styles.itemContent}>
                  <Text style={styles.itemTitle}>{task.title}</Text>
                  {task.assignedVendorName && (
                    <Text style={styles.itemSubtitle}>{task.assignedVendorName}</Text>
                  )}
                  <Text style={[styles.itemDue, task.isOverdue && styles.overdueDue]}>
                    {task.dueDate ? formatDate(task.dueDate) : 'No due date'} ({getDaysUntilLabel(task.daysUntilDue)})
                  </Text>
                </View>
                <View style={styles.itemRight}>
                  {task.estimatedCost !== undefined && (
                    <Text style={styles.itemAmount}>{formatCurrency(task.estimatedCost)}</Text>
                  )}
                  <View style={[styles.statusBadge, task.status === 'SCHEDULED' && styles.scheduledBadge]}>
                    <Text style={[styles.statusText, task.status === 'SCHEDULED' && styles.scheduledText]}>
                      {task.status}
                    </Text>
                  </View>
                </View>
              </View>
            ))
          )}
        </View>

        {/* Quick Actions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Quick Actions</Text>
          <View style={styles.actionsGrid}>
            <Link href="/(tabs)/new-request" asChild>
              <TouchableOpacity style={styles.actionCard}>
                <View style={[styles.actionIcon, styles.blueActionIcon]}>
                  <Text style={styles.actionEmoji}>💰</Text>
                </View>
                <Text style={styles.actionLabel}>Add a new bill</Text>
              </TouchableOpacity>
            </Link>
            <Link href="/(tabs)/new-request" asChild>
              <TouchableOpacity style={styles.actionCard}>
                <View style={[styles.actionIcon, styles.purpleActionIcon]}>
                  <Text style={styles.actionEmoji}>🔧</Text>
                </View>
                <Text style={styles.actionLabel}>Add a task</Text>
              </TouchableOpacity>
            </Link>
            <Link href="/(tabs)/new-request" asChild>
              <TouchableOpacity style={styles.actionCard}>
                <View style={[styles.actionIcon, styles.redActionIcon]}>
                  <Text style={styles.actionEmoji}>🚨</Text>
                </View>
                <Text style={styles.actionLabel}>Report issue</Text>
              </TouchableOpacity>
            </Link>
            <TouchableOpacity style={styles.actionCard}>
              <View style={[styles.actionIcon, styles.greenActionIcon]}>
                <Text style={styles.actionEmoji}>🔗</Text>
              </View>
              <Text style={styles.actionLabel}>Share profile</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.slate[50],
  },
  scrollContent: {
    padding: spacing[4],
  },
  // Hero Section
  heroSection: {
    backgroundColor: colors.primary[600],
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    marginBottom: spacing[5],
  },
  heroTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    marginBottom: spacing[2],
  },
  heroSubtitle: {
    fontSize: typography.fontSizes.base,
    color: 'rgba(255, 255, 255, 0.8)',
    lineHeight: 22,
  },
  nextUpCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginTop: spacing[4],
  },
  nextUpLabel: {
    fontSize: typography.fontSizes.sm,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: spacing[1],
  },
  nextUpContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  nextUpIcon: {
    fontSize: 28,
    marginRight: spacing[3],
  },
  nextUpDetails: {
    flex: 1,
  },
  nextUpTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  nextUpDue: {
    fontSize: typography.fontSizes.sm,
    color: 'rgba(255, 255, 255, 0.7)',
    marginTop: spacing[1],
  },
  // Today's Section
  todaySection: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[5],
    borderLeftWidth: 4,
    borderLeftColor: colors.warning,
    ...shadows.sm,
  },
  // Section styles
  section: {
    marginBottom: spacing[5],
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionIcon: {
    fontSize: 20,
    marginRight: spacing[2],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  countBadge: {
    backgroundColor: colors.warning + '30',
    borderRadius: borderRadius.full,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    marginLeft: spacing[2],
  },
  countBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.warning,
  },
  blueBadge: {
    backgroundColor: colors.primary[100],
  },
  blueBadgeText: {
    color: colors.primary[600],
  },
  purpleBadge: {
    backgroundColor: colors.accent[100],
  },
  purpleBadgeText: {
    color: colors.accent[600],
  },
  // Today Task Card
  todayTaskCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    marginBottom: spacing[2],
  },
  taskIcon: {
    fontSize: 22,
    marginRight: spacing[3],
  },
  taskContent: {
    flex: 1,
  },
  taskTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  taskVendor: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  taskRight: {
    alignItems: 'flex-end',
  },
  taskAmount: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  taskTime: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  // Empty card
  emptyCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[6],
    alignItems: 'center',
    ...shadows.sm,
  },
  emptyEmoji: {
    fontSize: 32,
    marginBottom: spacing[2],
  },
  emptyText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
    textAlign: 'center',
  },
  // Item card (bills/tasks)
  itemCard: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[3],
    borderWidth: 1,
    borderColor: colors.slate[200],
    ...shadows.sm,
  },
  overdueCard: {
    borderColor: colors.error,
    backgroundColor: '#FEF2F2',
  },
  itemIcon: {
    fontSize: 26,
    marginRight: spacing[3],
  },
  itemContent: {
    flex: 1,
  },
  itemTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  itemSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  itemDue: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: spacing[1],
  },
  overdueDue: {
    color: colors.error,
    fontWeight: typography.fontWeights.medium,
  },
  itemRight: {
    alignItems: 'flex-end',
  },
  itemAmount: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  askHaven: {
    fontSize: typography.fontSizes.xs,
    color: colors.primary[600],
    fontWeight: typography.fontWeights.medium,
    marginTop: spacing[2],
  },
  havenHandles: {
    fontSize: typography.fontSizes.xs,
    color: colors.success,
    fontWeight: typography.fontWeights.medium,
    marginTop: spacing[2],
  },
  statusBadge: {
    backgroundColor: colors.slate[100],
    borderRadius: borderRadius.full,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    marginTop: spacing[2],
  },
  statusText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[600],
  },
  scheduledBadge: {
    backgroundColor: colors.primary[100],
  },
  scheduledText: {
    color: colors.primary[600],
  },
  // Quick Actions
  actionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[3],
    marginTop: spacing[3],
  },
  actionCard: {
    width: '47%',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.slate[200],
    ...shadows.sm,
  },
  actionIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  actionEmoji: {
    fontSize: 24,
  },
  blueActionIcon: {
    backgroundColor: colors.primary[100],
  },
  purpleActionIcon: {
    backgroundColor: colors.accent[100],
  },
  redActionIcon: {
    backgroundColor: '#FEE2E2',
  },
  greenActionIcon: {
    backgroundColor: '#D1FAE5',
  },
  actionLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[700],
    fontWeight: typography.fontWeights.medium,
    textAlign: 'center',
  },
});
