import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
// Removed react-native-reanimated to fix Worklets crash
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Badge, SkeletonList, NoMaintenanceEmptyState, ErrorEmptyState } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

// =============================================================================
// TYPES - Match backend MaintenanceTaskResponseDto
// =============================================================================

interface ChecklistStep {
  id: string;
  completed: boolean;
}

interface MaintenanceTaskFromAPI {
  id: string;
  title: string;
  description: string | null;
  category: string;
  priority: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
  status: 'UPCOMING' | 'DUE' | 'OVERDUE' | 'COMPLETED' | 'CANCELLED' | 'PENDING' | 'SCHEDULED' | 'IN_PROGRESS' | 'SKIPPED';
  dueDate: string | null;
  nextDueDate: string | null;
  completedAt: string | null;
  frequency: string | null;
  estimatedCost: number | null;
  lastCompletedAt: string | null;
  checklistSteps?: ChecklistStep[] | null;
  vendor?: {
    id: string;
    companyName: string;
  } | null;
  assignedTo?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
  } | null;
  createdAt: string;
  updatedAt: string;
}

interface MaintenanceTask {
  id: string;
  title: string;
  description: string;
  category: string;
  dueDate: string;
  frequency: string;
  status: 'upcoming' | 'due' | 'overdue' | 'completed';
  estimatedCost?: number;
  lastCompleted?: string;
  assignedTo?: string;
  checklistTotal?: number;
  checklistCompleted?: number;
}

// Home systems type for Systems view
interface HomeSystem {
  id: string;
  name: string;
  category: string;
  icon: keyof typeof Ionicons.glyphMap;
  status: 'good' | 'needs_attention' | 'overdue';
  lastService?: string;
  nextService?: string;
  tasks: MaintenanceTask[];
}

type MaintenanceTab = 'tasks' | 'systems';

const CATEGORY_ICONS: Record<string, string> = {
  'HVAC': 'thermometer-outline',
  'Plumbing': 'water-outline',
  'PLUMBING': 'water-outline',
  'Electrical': 'flash-outline',
  'ELECTRICAL': 'flash-outline',
  'Exterior': 'home-outline',
  'EXTERIOR': 'home-outline',
  'Pool': 'water',
  'POOL': 'water',
  'Landscaping': 'leaf-outline',
  'LANDSCAPING': 'leaf-outline',
  'Safety': 'shield-checkmark-outline',
  'SAFETY': 'shield-checkmark-outline',
  'Appliances': 'cube-outline',
  'APPLIANCES': 'cube-outline',
  'APPLIANCE': 'cube-outline',
  'Roofing': 'umbrella-outline',
  'ROOFING': 'umbrella-outline',
  'GENERAL': 'construct-outline',
  'default': 'construct-outline',
};

// =============================================================================
// COMPONENT
// =============================================================================

export default function MaintenanceScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [tasks, setTasks] = useState<MaintenanceTask[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [filter, setFilter] = useState<'all' | 'upcoming' | 'overdue'>('all');
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<MaintenanceTab>('tasks');

  const convertTask = (apiTask: MaintenanceTaskFromAPI): MaintenanceTask => {
    const statusMap: Record<string, 'upcoming' | 'due' | 'overdue' | 'completed'> = {
      'UPCOMING': 'upcoming',
      'PENDING': 'upcoming',
      'SCHEDULED': 'upcoming',
      'IN_PROGRESS': 'due',
      'DUE': 'due',
      'OVERDUE': 'overdue',
      'COMPLETED': 'completed',
      'SKIPPED': 'completed',
      'CANCELLED': 'completed',
    };

    const assignedToName = apiTask.assignedTo
      ? `${apiTask.assignedTo.firstName || ''} ${apiTask.assignedTo.lastName || ''}`.trim()
      : apiTask.vendor?.companyName;

    // Calculate checklist progress
    const checklistSteps = apiTask.checklistSteps || [];
    const checklistTotal = checklistSteps.length;
    const checklistCompleted = checklistSteps.filter(s => s.completed).length;

    return {
      id: apiTask.id,
      title: apiTask.title,
      description: apiTask.description || '',
      category: apiTask.category,
      dueDate: apiTask.nextDueDate || apiTask.dueDate || apiTask.createdAt,
      frequency: apiTask.frequency || 'One-time',
      status: statusMap[apiTask.status] || 'upcoming',
      estimatedCost: apiTask.estimatedCost || undefined,
      lastCompleted: apiTask.lastCompletedAt || undefined,
      assignedTo: assignedToName || undefined,
      checklistTotal: checklistTotal > 0 ? checklistTotal : undefined,
      checklistCompleted: checklistTotal > 0 ? checklistCompleted : undefined,
    };
  };

  const fetchTasks = useCallback(async () => {
    if (!householdInfo?.id) {
      setError('No household found. Please complete onboarding.');
      setIsLoading(false);
      setIsRefreshing(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        setIsLoading(false);
        setIsRefreshing(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/maintenance-tasks?householdId=${householdInfo.id}&includeCompleted=true`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch tasks: ${response.status}`);
      }

      const apiTasks: MaintenanceTaskFromAPI[] = await response.json();
      const convertedTasks = apiTasks.map(convertTask);
      setTasks(convertedTasks);
      setError(null);
    } catch (err) {
      console.error('Fetch maintenance tasks error:', err);
      setError('Failed to load maintenance tasks. Please try again.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchTasks();
  }, [fetchTasks]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'overdue': return colors.status.error;
      case 'due': return colors.status.warning;
      case 'completed': return colors.status.success;
      default: return colors.haven.champagne[500];
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'overdue': return 'Overdue';
      case 'due': return 'Due Soon';
      case 'completed': return 'Completed';
      default: return 'Upcoming';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const filteredTasks = tasks.filter(task => {
    if (filter === 'all') return true;
    if (filter === 'upcoming') return task.status === 'upcoming' || task.status === 'due';
    if (filter === 'overdue') return task.status === 'overdue';
    return true;
  });

  const overdueCount = tasks.filter(t => t.status === 'overdue').length;

  // Derive systems from tasks
  const systems: HomeSystem[] = React.useMemo(() => {
    const categoryMap: Record<string, { tasks: MaintenanceTask[]; icon: keyof typeof Ionicons.glyphMap; name: string }> = {
      'HVAC': { tasks: [], icon: 'thermometer-outline', name: 'HVAC System' },
      'PLUMBING': { tasks: [], icon: 'water-outline', name: 'Plumbing' },
      'Plumbing': { tasks: [], icon: 'water-outline', name: 'Plumbing' },
      'ELECTRICAL': { tasks: [], icon: 'flash-outline', name: 'Electrical' },
      'Electrical': { tasks: [], icon: 'flash-outline', name: 'Electrical' },
      'EXTERIOR': { tasks: [], icon: 'home-outline', name: 'Exterior' },
      'Exterior': { tasks: [], icon: 'home-outline', name: 'Exterior' },
      'POOL': { tasks: [], icon: 'water', name: 'Pool & Spa' },
      'Pool': { tasks: [], icon: 'water', name: 'Pool & Spa' },
      'LANDSCAPING': { tasks: [], icon: 'leaf-outline', name: 'Landscaping' },
      'Landscaping': { tasks: [], icon: 'leaf-outline', name: 'Landscaping' },
      'SAFETY': { tasks: [], icon: 'shield-checkmark-outline', name: 'Safety Systems' },
      'Safety': { tasks: [], icon: 'shield-checkmark-outline', name: 'Safety Systems' },
      'APPLIANCES': { tasks: [], icon: 'cube-outline', name: 'Appliances' },
      'APPLIANCE': { tasks: [], icon: 'cube-outline', name: 'Appliances' },
      'ROOFING': { tasks: [], icon: 'umbrella-outline', name: 'Roofing' },
      'SEASONAL': { tasks: [], icon: 'calendar-outline', name: 'Seasonal' },
    };

    // Group tasks by category
    tasks.forEach(task => {
      const cat = task.category.toUpperCase();
      if (categoryMap[cat]) {
        categoryMap[cat].tasks.push(task);
      } else if (categoryMap[task.category]) {
        categoryMap[task.category].tasks.push(task);
      }
    });

    // Convert to array and calculate status
    const systemsArray: HomeSystem[] = [];
    const seenCategories = new Set<string>();

    Object.entries(categoryMap).forEach(([cat, data]) => {
      if (data.tasks.length === 0) return;
      const normalizedName = data.name;
      if (seenCategories.has(normalizedName)) return;
      seenCategories.add(normalizedName);

      const hasOverdue = data.tasks.some(t => t.status === 'overdue');
      const hasDue = data.tasks.some(t => t.status === 'due');
      const upcomingTasks = data.tasks.filter(t => t.status !== 'completed');
      const completedTasks = data.tasks.filter(t => t.status === 'completed');

      // Find next service date
      const nextTask = upcomingTasks.sort((a, b) =>
        new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime()
      )[0];

      // Find last completed
      const lastCompleted = completedTasks.sort((a, b) =>
        new Date(b.dueDate).getTime() - new Date(a.dueDate).getTime()
      )[0];

      systemsArray.push({
        id: cat,
        name: normalizedName,
        category: cat,
        icon: data.icon,
        status: hasOverdue ? 'overdue' : hasDue ? 'needs_attention' : 'good',
        nextService: nextTask?.dueDate,
        lastService: lastCompleted?.dueDate,
        tasks: data.tasks,
      });
    });

    return systemsArray.sort((a, b) => {
      // Sort by status priority: overdue first, then needs_attention, then good
      const statusOrder = { overdue: 0, needs_attention: 1, good: 2 };
      return statusOrder[a.status] - statusOrder[b.status];
    });
  }, [tasks]);

  const handleTaskPress = (taskId: string) => {
    router.push(`/(tabs)/maintenance/${taskId}` as any);
  };

  const renderTask = ({ item, index }: { item: MaintenanceTask; index: number }) => (
    <View
    >
    <TouchableOpacity activeOpacity={0.7} onPress={() => handleTaskPress(item.id)}>
    <Card style={styles.taskCard}>
      <View style={styles.taskHeader}>
        <View style={[styles.taskIcon, { backgroundColor: `${getStatusColor(item.status)}20` }]}>
          <Ionicons
            name={(CATEGORY_ICONS[item.category] || CATEGORY_ICONS.default) as any}
            size={20}
            color={getStatusColor(item.status)}
          />
        </View>
        <View style={styles.taskInfo}>
          <Text style={styles.taskTitle}>{item.title}</Text>
          <Text style={styles.taskCategory}>{item.category}</Text>
        </View>
        <Badge
          label={getStatusLabel(item.status)}
          variant={
            item.status === 'overdue' ? 'error' :
            item.status === 'due' ? 'warning' :
            item.status === 'completed' ? 'success' : 'default'
          }
          size="sm"
        />
      </View>

      {item.description && (
        <Text style={styles.taskDescription}>{item.description}</Text>
      )}

      <View style={styles.taskMeta}>
        <View style={styles.metaItem}>
          <Ionicons name="calendar-outline" size={14} color={colors.text.tertiary} />
          <Text style={styles.metaText}>
            {item.status === 'completed' ? 'Completed' : 'Due'}: {formatDate(item.dueDate)}
          </Text>
        </View>
        <View style={styles.metaItem}>
          <Ionicons name="repeat-outline" size={14} color={colors.text.tertiary} />
          <Text style={styles.metaText}>{item.frequency}</Text>
        </View>
        {item.estimatedCost !== undefined && item.estimatedCost > 0 && (
          <View style={styles.metaItem}>
            <Ionicons name="cash-outline" size={14} color={colors.text.tertiary} />
            <Text style={styles.metaText}>~${item.estimatedCost}</Text>
          </View>
        )}
      </View>

      {/* Checklist Progress Bar */}
      {item.checklistTotal !== undefined && item.checklistTotal > 0 && item.status !== 'completed' && (
        <View style={styles.progressContainer}>
          <View style={styles.progressInfo}>
            <Text style={styles.progressLabel}>Checklist</Text>
            <Text style={styles.progressCount}>{item.checklistCompleted}/{item.checklistTotal}</Text>
          </View>
          <View style={styles.progressBar}>
            <View
              style={[
                styles.progressFill,
                { width: `${((item.checklistCompleted || 0) / item.checklistTotal) * 100}%` },
              ]}
            />
          </View>
        </View>
      )}

      {item.assignedTo && (
        <View style={styles.assignedContainer}>
          <Ionicons name="person-outline" size={14} color={colors.haven.champagne[600]} />
          <Text style={styles.assignedText}>{item.assignedTo} is handling this</Text>
        </View>
      )}
    </Card>
    </TouchableOpacity>
    </View>
  );

  const getSystemStatusColor = (status: HomeSystem['status']) => {
    switch (status) {
      case 'overdue': return colors.status.error;
      case 'needs_attention': return colors.status.warning;
      default: return colors.status.success;
    }
  };

  const getSystemStatusLabel = (status: HomeSystem['status']) => {
    switch (status) {
      case 'overdue': return 'Needs Service';
      case 'needs_attention': return 'Due Soon';
      default: return 'Good';
    }
  };

  const renderSystem = ({ item, index }: { item: HomeSystem; index: number }) => (
    <View
    >
      <Card style={styles.systemCard}>
        <View style={styles.systemHeader}>
          <View style={[styles.systemIcon, { backgroundColor: `${getSystemStatusColor(item.status)}20` }]}>
            <Ionicons
              name={item.icon}
              size={24}
              color={getSystemStatusColor(item.status)}
            />
          </View>
          <View style={styles.systemInfo}>
            <Text style={styles.systemName}>{item.name}</Text>
            <Text style={styles.systemTaskCount}>
              {item.tasks.length} task{item.tasks.length !== 1 ? 's' : ''}
            </Text>
          </View>
          <View style={[styles.systemStatusBadge, { backgroundColor: `${getSystemStatusColor(item.status)}15` }]}>
            <View style={[styles.statusDot, { backgroundColor: getSystemStatusColor(item.status) }]} />
            <Text style={[styles.systemStatusText, { color: getSystemStatusColor(item.status) }]}>
              {getSystemStatusLabel(item.status)}
            </Text>
          </View>
        </View>

        <View style={styles.systemSchedule}>
          {item.nextService && (
            <View style={styles.scheduleItem}>
              <Ionicons name="calendar-outline" size={14} color={colors.text.tertiary} />
              <Text style={styles.scheduleLabel}>Next:</Text>
              <Text style={styles.scheduleDate}>{formatDate(item.nextService)}</Text>
            </View>
          )}
          {item.lastService && (
            <View style={styles.scheduleItem}>
              <Ionicons name="checkmark-circle-outline" size={14} color={colors.text.tertiary} />
              <Text style={styles.scheduleLabel}>Last:</Text>
              <Text style={styles.scheduleDate}>{formatDate(item.lastService)}</Text>
            </View>
          )}
        </View>

        {/* Upcoming tasks for this system */}
        {item.tasks.filter(t => t.status !== 'completed').slice(0, 3).map(task => (
          <TouchableOpacity
            key={task.id}
            style={styles.systemTaskItem}
            onPress={() => handleTaskPress(task.id)}
          >
            <View style={[styles.taskIndicator, { backgroundColor: getStatusColor(task.status) }]} />
            <Text style={styles.systemTaskTitle} numberOfLines={1}>{task.title}</Text>
            <Ionicons name="chevron-forward" size={16} color={colors.text.tertiary} />
          </TouchableOpacity>
        ))}
      </Card>
    </View>
  );

  if (isLoading) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <View style={styles.filterContainer}>
          {['All', 'Upcoming', 'Overdue'].map((label, i) => (
            <View key={label} style={[styles.filterTab, i === 0 && styles.filterTabActive]}>
              <Text style={[styles.filterText, i === 0 && styles.filterTextActive]}>{label}</Text>
            </View>
          ))}
        </View>
        <SkeletonList count={4} showCards />
      </SafeAreaView>
    );
  }

  if (error && tasks.length === 0) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <ErrorEmptyState onRetry={fetchTasks} />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      {/* Top-level Tabs */}
      <View style={styles.topTabsContainer}>
        <TouchableOpacity
          style={[styles.topTab, activeTab === 'tasks' && styles.topTabActive]}
          onPress={() => setActiveTab('tasks')}
        >
          <Ionicons
            name="list-outline"
            size={18}
            color={activeTab === 'tasks' ? colors.haven.navy[900] : colors.text.tertiary}
          />
          <Text style={[styles.topTabText, activeTab === 'tasks' && styles.topTabTextActive]}>
            Tasks
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.topTab, activeTab === 'systems' && styles.topTabActive]}
          onPress={() => setActiveTab('systems')}
        >
          <Ionicons
            name="hardware-chip-outline"
            size={18}
            color={activeTab === 'systems' ? colors.haven.navy[900] : colors.text.tertiary}
          />
          <Text style={[styles.topTabText, activeTab === 'systems' && styles.topTabTextActive]}>
            Systems
          </Text>
        </TouchableOpacity>
      </View>

      {activeTab === 'tasks' ? (
        <>
          {/* Filter Tabs */}
          <View style={styles.filterContainer}>
            <TouchableOpacity
              style={[styles.filterTab, filter === 'all' && styles.filterTabActive]}
              onPress={() => setFilter('all')}
            >
              <Text style={[styles.filterText, filter === 'all' && styles.filterTextActive]}>
                All
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.filterTab, filter === 'upcoming' && styles.filterTabActive]}
              onPress={() => setFilter('upcoming')}
            >
              <Text style={[styles.filterText, filter === 'upcoming' && styles.filterTextActive]}>
                Upcoming
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.filterTab, filter === 'overdue' && styles.filterTabActive]}
              onPress={() => setFilter('overdue')}
            >
              <Text style={[styles.filterText, filter === 'overdue' && styles.filterTextActive]}>
                Overdue
              </Text>
              {overdueCount > 0 && (
                <View style={styles.filterBadge}>
                  <Text style={styles.filterBadgeText}>{overdueCount}</Text>
                </View>
              )}
            </TouchableOpacity>
          </View>

          {/* Tasks List */}
          <FlatList
            data={filteredTasks}
            renderItem={renderTask}
            keyExtractor={(item) => item.id}
            contentContainerStyle={styles.listContent}
            refreshControl={
              <RefreshControl
                refreshing={isRefreshing}
                onRefresh={() => {
                  setIsRefreshing(true);
                  fetchTasks();
                }}
              />
            }
            ListEmptyComponent={
              <NoMaintenanceEmptyState
                onAction={() => router.push('/(tabs)/manager/new-request' as any)}
              />
            }
          />
        </>
      ) : (
        /* Systems View */
        <FlatList
          data={systems}
          renderItem={renderSystem}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContent}
          refreshControl={
            <RefreshControl
              refreshing={isRefreshing}
              onRefresh={() => {
                setIsRefreshing(true);
                fetchTasks();
              }}
            />
          }
          ListHeaderComponent={
            <View style={styles.systemsHeader}>
              <View style={styles.systemsHeaderRow}>
                <View style={styles.systemsHeaderText}>
                  <Text style={styles.systemsHeaderTitle}>Home Systems</Text>
                  <Text style={styles.systemsHeaderSubtitle}>
                    Tap a system to view and manage maintenance tasks
                  </Text>
                </View>
                <TouchableOpacity
                  style={styles.addSystemButton}
                  onPress={() => router.push('/(tabs)/manager/new-request' as any)}
                >
                  <Ionicons name="add" size={18} color={colors.haven.champagne[500]} />
                  <Text style={styles.addSystemText}>Add</Text>
                </TouchableOpacity>
              </View>
            </View>
          }
          ListEmptyComponent={
            <View style={styles.emptySystemsContainer}>
              <Ionicons name="hardware-chip-outline" size={48} color={colors.text.tertiary} />
              <Text style={styles.emptySystemsTitle}>No Systems Yet</Text>
              <Text style={styles.emptySystemsText}>
                Track your home's major systems and their maintenance schedules
              </Text>
              <TouchableOpacity
                style={styles.addFirstSystemButton}
                onPress={() => router.push('/(tabs)/manager/new-request' as any)}
              >
                <Ionicons name="add-circle-outline" size={20} color={colors.white} />
                <Text style={styles.addFirstSystemText}>Add First System</Text>
              </TouchableOpacity>
            </View>
          }
        />
      )}
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
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  errorTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
  retryButton: {
    marginTop: spacing[4],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  filterContainer: {
    flexDirection: 'row',
    padding: spacing[4],
    gap: spacing[2],
  },
  filterTab: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
  },
  filterTabActive: {
    backgroundColor: colors.haven.navy[900],
  },
  filterText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  filterTextActive: {
    color: colors.white,
  },
  filterBadge: {
    marginLeft: spacing[2],
    backgroundColor: colors.status.error,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  filterBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  listContent: {
    padding: spacing[4],
    paddingTop: 0,
  },
  taskCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  taskHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  taskIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  taskInfo: {
    flex: 1,
  },
  taskTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  taskCategory: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  taskDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[3],
    lineHeight: 20,
  },
  taskMeta: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[4],
  },
  metaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  metaText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  assignedContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[2],
  },
  assignedText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
  },
  progressContainer: {
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  progressInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  progressLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  progressCount: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[900],
  },
  progressBar: {
    height: 6,
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.full,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.haven.navy[900],
    borderRadius: borderRadius.full,
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
  // Top-level tabs
  topTabsContainer: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    paddingHorizontal: spacing[4],
    paddingTop: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  topTab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  topTabActive: {
    borderBottomColor: colors.haven.navy[900],
  },
  topTabText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.tertiary,
  },
  topTabTextActive: {
    color: colors.haven.navy[900],
    fontWeight: typography.fontWeights.semibold,
  },
  // Systems view
  systemCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  systemHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  systemIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  systemInfo: {
    flex: 1,
  },
  systemName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  systemTaskCount: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  systemStatusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
    gap: spacing[1],
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  systemStatusText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
  },
  systemSchedule: {
    flexDirection: 'row',
    gap: spacing[4],
    marginBottom: spacing[3],
    paddingBottom: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  scheduleItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  scheduleLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  scheduleDate: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  systemTaskItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
  },
  taskIndicator: {
    width: 4,
    height: 4,
    borderRadius: 2,
    marginRight: spacing[2],
  },
  systemTaskTitle: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  systemsHeader: {
    paddingTop: spacing[5],  // Gap after tab bar
    paddingBottom: spacing[4],
  },
  systemsHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  systemsHeaderText: {
    flex: 1,
  },
  systemsHeaderTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  systemsHeaderSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  addSystemButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.haven.champagne[50],
    borderRadius: borderRadius.lg,
  },
  addSystemText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[600],
  },
  emptySystemsContainer: {
    alignItems: 'center',
    paddingVertical: spacing[10],
  },
  emptySystemsTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  emptySystemsText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
    textAlign: 'center',
    paddingHorizontal: spacing[6],
  },
  addFirstSystemButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: spacing[4],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[5],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
  },
  addFirstSystemText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
});
