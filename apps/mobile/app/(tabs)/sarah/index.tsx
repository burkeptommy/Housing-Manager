import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Linking,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner, Button } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

interface Approval {
  id: string;
  title: string;
  description?: string;
  amount?: number;
  status: string;
  createdAt: string;
}

interface Request {
  id: string;
  subject: string;
  status: string;
  createdAt: string;
}

interface Activity {
  id: string;
  type: 'approval' | 'request' | 'message' | 'update';
  title: string;
  description: string;
  timestamp: string;
}

export default function SarahHubScreen() {
  const router = useRouter();
  const { user, householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [pendingApprovals, setPendingApprovals] = useState<Approval[]>([]);
  const [activeRequests, setActiveRequests] = useState<Request[]>([]);
  const [recentActivity, setRecentActivity] = useState<Activity[]>([]);
  const [managerName, setManagerName] = useState('Sarah Chen');
  const [managerPhone, setManagerPhone] = useState('+1 (555) 123-4567');

  const fetchData = useCallback(async () => {
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

      // Fetch approvals
      const approvalsRes = await fetch(`${API_BASE_URL}/approvals`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (approvalsRes.ok) {
        const approvals = await approvalsRes.json();
        setPendingApprovals(approvals.filter((a: Approval) => a.status === 'PENDING').slice(0, 3));
      }

      // Fetch conversations (requests)
      const conversationsRes = await fetch(`${API_BASE_URL}/conversations`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (conversationsRes.ok) {
        const conversations = await conversationsRes.json();
        setActiveRequests(
          conversations
            .filter((c: Request) => c.status === 'OPEN' || c.status === 'PENDING')
            .slice(0, 3)
        );
      }

      // Build recent activity from both sources
      const activities: Activity[] = [];

      // Add recent approvals to activity
      if (approvalsRes.ok) {
        const approvals = await approvalsRes.json();
        approvals.slice(0, 2).forEach((a: Approval) => {
          activities.push({
            id: `approval-${a.id}`,
            type: 'approval',
            title: a.status === 'APPROVED' ? 'Approval Completed' : a.status === 'PENDING' ? 'Awaiting Approval' : 'Update',
            description: a.title,
            timestamp: a.createdAt,
          });
        });
      }

      setRecentActivity(activities.slice(0, 5));
    } catch (err) {
      console.error('Fetch hub data error:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleCall = () => {
    Linking.openURL(`tel:${managerPhone.replace(/[^0-9+]/g, '')}`);
  };

  const handleApprove = async (approvalId: string) => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      await fetch(`${API_BASE_URL}/approvals/${approvalId}/approve`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });

      setPendingApprovals(prev => prev.filter(a => a.id !== approvalId));
    } catch (err) {
      console.error('Approve error:', err);
    }
  };

  const handleReject = async (approvalId: string) => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      await fetch(`${API_BASE_URL}/approvals/${approvalId}/reject`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });

      setPendingApprovals(prev => prev.filter(a => a.id !== approvalId));
    } catch (err) {
      console.error('Reject error:', err);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return date.toLocaleDateString('en-US', { weekday: 'short' });
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const getActivityIcon = (type: Activity['type']) => {
    switch (type) {
      case 'approval': return 'checkmark-circle';
      case 'request': return 'construct';
      case 'message': return 'chatbubble';
      default: return 'notifications';
    }
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchData();
            }}
          />
        }
      >
        {/* Manager Profile Card */}
        <Card style={styles.managerCard}>
          <View style={styles.managerHeader}>
            <View style={styles.managerAvatar}>
              <Text style={styles.managerInitials}>SC</Text>
            </View>
            <View style={styles.managerInfo}>
              <Text style={styles.managerName}>{managerName}</Text>
              <Text style={styles.managerRole}>Your Home Manager</Text>
            </View>
            <View style={styles.statusIndicator}>
              <View style={styles.statusDot} />
              <Text style={styles.statusText}>Available</Text>
            </View>
          </View>
          <View style={styles.managerActions}>
            <TouchableOpacity style={styles.actionButton} onPress={handleCall}>
              <Ionicons name="call" size={20} color={colors.haven.purple[600]} />
              <Text style={styles.actionButtonText}>Call</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.actionButton, styles.actionButtonPrimary]}
              onPress={() => router.push('/(tabs)/sarah/chat' as any)}
            >
              <Ionicons name="chatbubble" size={20} color={colors.white} />
              <Text style={styles.actionButtonTextPrimary}>Message</Text>
            </TouchableOpacity>
          </View>
        </Card>

        {/* Pending Approvals */}
        {pendingApprovals.length > 0 && (
          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>Pending Approvals</Text>
              <TouchableOpacity onPress={() => router.push('/(tabs)/approvals' as any)}>
                <Text style={styles.seeAllText}>See All</Text>
              </TouchableOpacity>
            </View>
            {pendingApprovals.map((approval) => (
              <Card key={approval.id} style={styles.approvalCard}>
                <View style={styles.approvalHeader}>
                  <View style={styles.approvalInfo}>
                    <Text style={styles.approvalTitle} numberOfLines={1}>{approval.title}</Text>
                    {approval.amount && (
                      <Text style={styles.approvalAmount}>
                        ${approval.amount.toLocaleString()}
                      </Text>
                    )}
                  </View>
                  <Badge label="Pending" variant="warning" size="sm" />
                </View>
                <View style={styles.approvalActions}>
                  <TouchableOpacity
                    style={styles.rejectButton}
                    onPress={() => handleReject(approval.id)}
                  >
                    <Ionicons name="close" size={18} color={colors.status.error} />
                    <Text style={styles.rejectButtonText}>Reject</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.approveButton}
                    onPress={() => handleApprove(approval.id)}
                  >
                    <Ionicons name="checkmark" size={18} color={colors.white} />
                    <Text style={styles.approveButtonText}>Approve</Text>
                  </TouchableOpacity>
                </View>
              </Card>
            ))}
          </View>
        )}

        {/* Active Requests */}
        {activeRequests.length > 0 && (
          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>Active Requests</Text>
              <TouchableOpacity onPress={() => router.push('/(tabs)/sarah/requests' as any)}>
                <Text style={styles.seeAllText}>See All</Text>
              </TouchableOpacity>
            </View>
            {activeRequests.map((request) => (
              <TouchableOpacity
                key={request.id}
                onPress={() => router.push('/(tabs)/sarah/chat' as any)}
              >
                <Card style={styles.requestCard}>
                  <View style={styles.requestIcon}>
                    <Ionicons name="construct-outline" size={20} color={colors.haven.purple[500]} />
                  </View>
                  <View style={styles.requestInfo}>
                    <Text style={styles.requestTitle} numberOfLines={1}>{request.subject}</Text>
                    <Text style={styles.requestDate}>{formatDate(request.createdAt)}</Text>
                  </View>
                  <Badge
                    label={request.status === 'OPEN' ? 'Open' : 'In Progress'}
                    variant={request.status === 'OPEN' ? 'warning' : 'default'}
                    size="sm"
                  />
                  <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
                </Card>
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* Recent Activity */}
        {recentActivity.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Recent Updates</Text>
            <Card style={styles.activityCard}>
              {recentActivity.map((activity, index) => (
                <View
                  key={activity.id}
                  style={[
                    styles.activityItem,
                    index < recentActivity.length - 1 && styles.activityItemBorder,
                  ]}
                >
                  <View style={styles.activityIcon}>
                    <Ionicons
                      name={getActivityIcon(activity.type) as any}
                      size={16}
                      color={colors.haven.purple[500]}
                    />
                  </View>
                  <View style={styles.activityContent}>
                    <Text style={styles.activityTitle}>{activity.title}</Text>
                    <Text style={styles.activityDescription} numberOfLines={1}>
                      {activity.description}
                    </Text>
                  </View>
                  <Text style={styles.activityTime}>{formatDate(activity.timestamp)}</Text>
                </View>
              ))}
            </Card>
          </View>
        )}

        {/* Quick Actions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Quick Actions</Text>
          <View style={styles.quickActions}>
            <TouchableOpacity
              style={styles.quickActionCard}
              onPress={() => router.push('/(tabs)/sarah/new-request' as any)}
            >
              <View style={styles.quickActionIcon}>
                <Ionicons name="add-circle" size={28} color={colors.haven.purple[500]} />
              </View>
              <Text style={styles.quickActionText}>New Request</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.quickActionCard}
              onPress={() => router.push('/(tabs)/sarah/chat' as any)}
            >
              <View style={styles.quickActionIcon}>
                <Ionicons name="chatbubbles" size={28} color={colors.haven.purple[500]} />
              </View>
              <Text style={styles.quickActionText}>Chat</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.quickActionCard}
              onPress={() => router.push('/(tabs)/sarah/requests' as any)}
            >
              <View style={styles.quickActionIcon}>
                <Ionicons name="list" size={28} color={colors.haven.purple[500]} />
              </View>
              <Text style={styles.quickActionText}>All Requests</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Empty State */}
        {pendingApprovals.length === 0 && activeRequests.length === 0 && (
          <Card style={styles.emptyCard}>
            <Ionicons name="checkmark-done-circle" size={48} color={colors.haven.purple[300]} />
            <Text style={styles.emptyTitle}>All caught up!</Text>
            <Text style={styles.emptyText}>
              No pending approvals or active requests. Need something?
            </Text>
            <Button
              title="Create New Request"
              onPress={() => router.push('/(tabs)/sarah/new-request' as any)}
              style={{ marginTop: spacing[4] }}
            />
          </Card>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
  },
  managerCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  managerHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  managerAvatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.purple[500],
    alignItems: 'center',
    justifyContent: 'center',
  },
  managerInitials: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  managerInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  managerName: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  managerRole: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  statusIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.status.success + '15',
    paddingHorizontal: spacing[2],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.status.success,
    marginRight: spacing[1],
  },
  statusText: {
    fontSize: typography.fontSizes.xs,
    color: colors.status.success,
    fontWeight: typography.fontWeights.medium,
  },
  managerActions: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
    backgroundColor: colors.haven.purple[50],
  },
  actionButtonPrimary: {
    backgroundColor: colors.haven.purple[500],
    borderColor: colors.haven.purple[500],
  },
  actionButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[600],
  },
  actionButtonTextPrimary: {
    color: colors.white,
  },
  section: {
    marginBottom: spacing[5],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  seeAllText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    fontWeight: typography.fontWeights.medium,
  },
  approvalCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  approvalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[3],
  },
  approvalInfo: {
    flex: 1,
    marginRight: spacing[2],
  },
  approvalTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  approvalAmount: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
    marginTop: spacing[1],
  },
  approvalActions: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  rejectButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[1],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.status.error,
    backgroundColor: colors.white,
  },
  rejectButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.error,
  },
  approveButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[1],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.status.success,
  },
  approveButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.white,
  },
  requestCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  requestIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  requestInfo: {
    flex: 1,
    marginRight: spacing[2],
  },
  requestTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  requestDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  activityCard: {
    padding: 0,
    overflow: 'hidden',
  },
  activityItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
  },
  activityItemBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  activityIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  activityContent: {
    flex: 1,
  },
  activityTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  activityDescription: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  activityTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  quickActions: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  quickActionCard: {
    flex: 1,
    alignItems: 'center',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    shadowColor: colors.haven.purple[900],
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 3,
    elevation: 2,
  },
  quickActionIcon: {
    marginBottom: spacing[2],
  },
  quickActionText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    textAlign: 'center',
  },
  emptyCard: {
    padding: spacing[6],
    alignItems: 'center',
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
  },
});
