import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { Card } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';
import { API_BASE_URL } from '../../src/lib/api';
import { getIdToken } from '../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface Activity {
  id: string;
  title: string;
  description: string | null;
  actorName: string | null;
  category: string;
  action: string;
  createdAt: string;
}

// =============================================================================
// HELPERS
// =============================================================================

function formatRelativeTime(dateString: string) {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function getActivityConfig(category: string): { emoji: string; bgColor: string; label: string } {
  const configs: Record<string, { emoji: string; bgColor: string; label: string }> = {
    PROPERTY: { emoji: '🏠', bgColor: '#E0E7FF', label: 'Property' },
    BILLING: { emoji: '💰', bgColor: '#D1FAE5', label: 'Billing' },
    FAMILY: { emoji: '👨‍👩‍👧‍👦', bgColor: '#FCE7F3', label: 'Family' },
    MAINTENANCE: { emoji: '🔧', bgColor: '#FEF3C7', label: 'Maintenance' },
    SERVICE: { emoji: '👷', bgColor: '#DBEAFE', label: 'Service' },
    COMMUNICATION: { emoji: '💬', bgColor: '#F3E8FF', label: 'Communication' },
    SYSTEM: { emoji: '🤖', bgColor: '#E5E7EB', label: 'System' },
  };
  return configs[category] || { emoji: '📌', bgColor: '#F3F4F6', label: 'Other' };
}

// =============================================================================
// COMPONENT
// =============================================================================

export default function ActivityScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [activities, setActivities] = useState<Activity[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);

  const categories = ['PROPERTY', 'BILLING', 'FAMILY', 'MAINTENANCE', 'SERVICE', 'COMMUNICATION', 'SYSTEM'];

  const fetchActivities = useCallback(async () => {
    if (!householdInfo?.id) {
      setIsLoading(false);
      setError('No household found');
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired');
        setIsLoading(false);
        return;
      }

      let url = `${API_BASE_URL}/activity/household/${householdInfo.id}?limit=50`;
      if (selectedCategory) {
        url += `&category=${selectedCategory}`;
      }

      const response = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch activities: ${response.status}`);
      }

      const data = await response.json();
      setActivities(data);
      setError(null);
    } catch (err) {
      console.error('Activity fetch error:', err);
      setError('Failed to load activities');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id, selectedCategory]);

  useEffect(() => {
    fetchActivities();
  }, [fetchActivities]);

  const onRefresh = () => {
    setIsRefreshing(true);
    fetchActivities();
  };

  if (isLoading) {
    return (
      <View style={styles.safeAreaWrapper}>
        <SafeAreaView style={styles.safeAreaTop} edges={['top']} />
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.navigate('/more')} style={styles.backButton}>
            <Ionicons name="chevron-back" size={24} color={colors.white} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Activity</Text>
          <View style={styles.headerRight} />
        </View>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.purple[500]} />
        </View>
      </View>
    );
  }

  return (
    <View style={styles.safeAreaWrapper}>
      <SafeAreaView style={styles.safeAreaTop} edges={['top']} />
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.navigate('/more')} style={styles.backButton}>
          <Ionicons name="chevron-back" size={24} color={colors.white} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Activity</Text>
        <View style={styles.headerRight} />
      </View>

      {/* Category Filter */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.filterContainer}
        contentContainerStyle={styles.filterContent}
      >
        <TouchableOpacity
          style={[styles.filterChip, !selectedCategory && styles.filterChipActive]}
          onPress={() => setSelectedCategory(null)}
        >
          <Text style={[styles.filterChipText, !selectedCategory && styles.filterChipTextActive]}>
            All
          </Text>
        </TouchableOpacity>
        {categories.map((cat) => {
          const config = getActivityConfig(cat);
          const isActive = selectedCategory === cat;
          return (
            <TouchableOpacity
              key={cat}
              style={[styles.filterChip, isActive && styles.filterChipActive]}
              onPress={() => setSelectedCategory(isActive ? null : cat)}
            >
              <Text style={styles.filterChipEmoji}>{config.emoji}</Text>
              <Text style={[styles.filterChipText, isActive && styles.filterChipTextActive]}>
                {config.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      <ScrollView
        style={styles.mainContent}
        contentContainerStyle={styles.scrollContent}
        refreshControl={<RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />}
        showsVerticalScrollIndicator={false}
      >
        {error ? (
          <View style={styles.errorContainer}>
            <Ionicons name="alert-circle" size={48} color={colors.status.error} />
            <Text style={styles.errorText}>{error}</Text>
            <TouchableOpacity style={styles.retryButton} onPress={fetchActivities}>
              <Text style={styles.retryText}>Try Again</Text>
            </TouchableOpacity>
          </View>
        ) : activities.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Ionicons name="newspaper-outline" size={48} color={colors.gray[300]} />
            <Text style={styles.emptyTitle}>No Activity Yet</Text>
            <Text style={styles.emptyText}>
              Activities will appear here as things happen in your home
            </Text>
          </View>
        ) : (
          <Card style={styles.activityList}>
            {activities.map((activity, index) => {
              const config = getActivityConfig(activity.category);
              return (
                <View
                  key={activity.id}
                  style={[
                    styles.activityItem,
                    index < activities.length - 1 && styles.activityItemBorder,
                  ]}
                >
                  <View style={[styles.activityEmoji, { backgroundColor: config.bgColor }]}>
                    <Text style={styles.activityEmojiText}>{config.emoji}</Text>
                  </View>
                  <View style={styles.activityContent}>
                    <Text style={styles.activityTitle}>{activity.title}</Text>
                    {activity.description && (
                      <Text style={styles.activityDescription} numberOfLines={2}>
                        {activity.description}
                      </Text>
                    )}
                    <View style={styles.activityMeta}>
                      {activity.actorName && (
                        <>
                          <Text style={styles.activityActor}>{activity.actorName}</Text>
                          <Text style={styles.activityDot}>·</Text>
                        </>
                      )}
                      <Text style={styles.activityTime}>
                        {formatRelativeTime(activity.createdAt)}
                      </Text>
                    </View>
                  </View>
                </View>
              );
            })}
          </Card>
        )}
      </ScrollView>
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  safeAreaWrapper: {
    flex: 1,
    backgroundColor: colors.haven.purple[950],
  },
  safeAreaTop: {
    backgroundColor: colors.haven.purple[950],
  },
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.purple[950],
  },
  backButton: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  headerRight: {
    width: 40,
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.slate[50],
  },
  mainContent: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  filterContainer: {
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
    flexGrow: 0,
    flexShrink: 0,
  },
  filterContent: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    gap: spacing[2],
  },
  filterChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    backgroundColor: colors.gray[100],
    marginRight: spacing[2],
    gap: spacing[1],
  },
  filterChipActive: {
    backgroundColor: colors.haven.purple[950],
  },
  filterChipEmoji: {
    fontSize: 14,
  },
  filterChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  filterChipTextActive: {
    color: colors.white,
  },
  scrollContent: {
    padding: spacing[4],
  },
  errorContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[8],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[3],
  },
  retryButton: {
    marginTop: spacing[4],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.purple[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[8],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[3],
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
  activityList: {
    padding: spacing[3],
  },
  activityItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    gap: spacing[3],
  },
  activityItemBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  activityEmoji: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  activityEmojiText: {
    fontSize: 20,
  },
  activityContent: {
    flex: 1,
  },
  activityTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  activityDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 4,
    lineHeight: 20,
  },
  activityMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[2],
    gap: spacing[1],
  },
  activityActor: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  activityDot: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  activityTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
});
