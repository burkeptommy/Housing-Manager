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
import type { ServiceRequest, ServiceRequestStatus, ServiceRequestPriority } from '@haven/core';

const STATUS_COLORS: Record<ServiceRequestStatus, string> = {
  DRAFT: colors.slate[400],
  SUBMITTED: colors.info,
  ASSIGNED: colors.accent[500],
  IN_PROGRESS: colors.warning,
  COMPLETED: colors.success,
  CANCELLED: colors.slate[400],
};

const PRIORITY_COLORS: Record<ServiceRequestPriority, string> = {
  LOW: colors.slate[400],
  MEDIUM: colors.info,
  HIGH: colors.warning,
  URGENT: colors.error,
};

export default function HomeScreen() {
  const { user, currentHousehold, refreshCurrentHousehold } = useAuth();
  const [requests, setRequests] = useState<ServiceRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const api = getApiClient();

  const fetchData = useCallback(async () => {
    if (!currentHousehold) return;

    try {
      const requestsData = await api.getServiceRequests(currentHousehold.id);
      setRequests(requestsData);
    } catch (error) {
      console.error('Failed to fetch data:', error);
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

  const openRequests = requests.filter(
    (r) => r.status !== 'COMPLETED' && r.status !== 'CANCELLED'
  );
  const recentCompleted = requests
    .filter((r) => r.status === 'COMPLETED')
    .slice(0, 3);

  if (isLoading) {
    return (
      <SafeAreaView style={styles.loadingContainer} edges={['bottom']}>
        <ActivityIndicator size="large" color={colors.primary[600]} />
      </SafeAreaView>
    );
  }

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
        {/* Welcome Section */}
        <View style={styles.welcomeSection}>
          <Text style={styles.welcomeText}>
            Welcome back, {user?.firstName}!
          </Text>
          {currentHousehold && (
            <Text style={styles.householdName}>{currentHousehold.name}</Text>
          )}
        </View>

        {/* Quick Stats */}
        <View style={styles.statsRow}>
          <View style={styles.statCard}>
            <Text style={styles.statNumber}>{openRequests.length}</Text>
            <Text style={styles.statLabel}>Open Requests</Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statNumber}>
              {requests.filter((r) => r.status === 'IN_PROGRESS').length}
            </Text>
            <Text style={styles.statLabel}>In Progress</Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statNumber}>
              {requests.filter((r) => r.status === 'COMPLETED').length}
            </Text>
            <Text style={styles.statLabel}>Completed</Text>
          </View>
        </View>

        {/* Open Requests */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Open Requests</Text>
            {openRequests.length > 0 && (
              <View style={styles.badge}>
                <Text style={styles.badgeText}>{openRequests.length}</Text>
              </View>
            )}
          </View>

          {openRequests.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyText}>No open requests</Text>
              <Link href="/(tabs)/new-request" asChild>
                <TouchableOpacity style={styles.emptyButton}>
                  <Text style={styles.emptyButtonText}>Create Request</Text>
                </TouchableOpacity>
              </Link>
            </View>
          ) : (
            openRequests.slice(0, 5).map((request) => (
              <RequestCard key={request.id} request={request} />
            ))
          )}
        </View>

        {/* Recently Completed */}
        {recentCompleted.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Recently Completed</Text>
            {recentCompleted.map((request) => (
              <RequestCard key={request.id} request={request} />
            ))}
          </View>
        )}

        {/* Quick Actions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Quick Actions</Text>
          <View style={styles.actionsGrid}>
            <Link href="/(tabs)/new-request" asChild>
              <TouchableOpacity style={styles.actionCard}>
                <View style={[styles.actionIcon, { backgroundColor: colors.primary[100] }]}>
                  <Text style={[styles.actionIconText, { color: colors.primary[600] }]}>+</Text>
                </View>
                <Text style={styles.actionLabel}>New Request</Text>
              </TouchableOpacity>
            </Link>
            <Link href="/(tabs)/chat" asChild>
              <TouchableOpacity style={styles.actionCard}>
                <View style={[styles.actionIcon, { backgroundColor: colors.accent[100] }]}>
                  <Text style={[styles.actionIconText, { color: colors.accent[600] }]}>💬</Text>
                </View>
                <Text style={styles.actionLabel}>Messages</Text>
              </TouchableOpacity>
            </Link>
            <Link href="/(tabs)/settings" asChild>
              <TouchableOpacity style={styles.actionCard}>
                <View style={[styles.actionIcon, { backgroundColor: colors.slate[100] }]}>
                  <Text style={[styles.actionIconText, { color: colors.slate[600] }]}>⚙</Text>
                </View>
                <Text style={styles.actionLabel}>Settings</Text>
              </TouchableOpacity>
            </Link>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function RequestCard({ request }: { request: ServiceRequest }) {
  return (
    <View style={styles.requestCard}>
      <View style={styles.requestHeader}>
        <Text style={styles.requestTitle} numberOfLines={1}>
          {request.title}
        </Text>
        <View
          style={[
            styles.statusBadge,
            { backgroundColor: STATUS_COLORS[request.status] + '20' },
          ]}
        >
          <View
            style={[
              styles.statusDot,
              { backgroundColor: STATUS_COLORS[request.status] },
            ]}
          />
          <Text
            style={[
              styles.statusText,
              { color: STATUS_COLORS[request.status] },
            ]}
          >
            {request.status.replace('_', ' ')}
          </Text>
        </View>
      </View>
      <Text style={styles.requestDescription} numberOfLines={2}>
        {request.description}
      </Text>
      <View style={styles.requestFooter}>
        <View
          style={[
            styles.priorityBadge,
            { backgroundColor: PRIORITY_COLORS[request.priority] + '20' },
          ]}
        >
          <Text
            style={[
              styles.priorityText,
              { color: PRIORITY_COLORS[request.priority] },
            ]}
          >
            {request.priority}
          </Text>
        </View>
        <Text style={styles.requestDate}>
          {new Date(request.createdAt).toLocaleDateString()}
        </Text>
      </View>
    </View>
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
  welcomeSection: {
    marginBottom: spacing[6],
  },
  welcomeText: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  householdName: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
    marginTop: spacing[1],
  },
  statsRow: {
    flexDirection: 'row',
    gap: spacing[3],
    marginBottom: spacing[6],
  },
  statCard: {
    flex: 1,
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    alignItems: 'center',
    ...shadows.sm,
  },
  statNumber: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.primary[600],
  },
  statLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: spacing[1],
  },
  section: {
    marginBottom: spacing[6],
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  badge: {
    backgroundColor: colors.primary[600],
    borderRadius: borderRadius.full,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    marginLeft: spacing[2],
  },
  badgeText: {
    color: colors.white,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
  },
  emptyCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[6],
    alignItems: 'center',
    ...shadows.sm,
  },
  emptyText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
    marginBottom: spacing[4],
  },
  emptyButton: {
    backgroundColor: colors.primary[600],
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
  },
  emptyButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
  },
  requestCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[3],
    ...shadows.sm,
  },
  requestHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[2],
  },
  requestTitle: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginRight: spacing[2],
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing[2],
    paddingVertical: 4,
    borderRadius: borderRadius.full,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginRight: 4,
  },
  statusText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
  },
  requestDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginBottom: spacing[3],
  },
  requestFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  priorityBadge: {
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
  },
  priorityText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
  },
  requestDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
  },
  actionsGrid: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  actionCard: {
    flex: 1,
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    alignItems: 'center',
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
  actionIconText: {
    fontSize: 24,
  },
  actionLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[700],
    fontWeight: typography.fontWeights.medium,
  },
});
