import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Alert,
  RefreshControl,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Badge, Button, LoadingSpinner, ScreenContainer } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

// =============================================================================
// TYPES - Match backend ApprovalService response
// =============================================================================

interface ApprovalFromAPI {
  id: string;
  title: string;
  description: string | null;
  amount: number;
  category: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  priority: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
  dueDate: string | null;
  decisionNote: string | null;
  decidedAt: string | null;
  createdAt: string;
  updatedAt: string;
  requestedBy: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    role: string;
  };
  decidedBy?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
  } | null;
  vendor?: {
    id: string;
    companyName: string;
  } | null;
  attachments?: Array<{
    id: string;
    url: string;
    filename: string;
  }>;
}

interface Approval {
  id: string;
  title: string;
  description: string;
  amount: number;
  category: string;
  requestedBy: string;
  requestedAt: string;
  status: 'pending' | 'approved' | 'rejected';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  vendor?: string;
  attachments?: string[];
}

// =============================================================================
// COMPONENT
// =============================================================================

export default function ApprovalsScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [approvals, setApprovals] = useState<Approval[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isProcessing, setIsProcessing] = useState<string | null>(null);
  const [filter, setFilter] = useState<'pending' | 'all'>('pending');
  const [error, setError] = useState<string | null>(null);

  const convertApproval = (apiApproval: ApprovalFromAPI): Approval => {
    const requestedByName = apiApproval.requestedBy
      ? `${apiApproval.requestedBy.firstName || ''} ${apiApproval.requestedBy.lastName || ''}`.trim() || 'Unknown'
      : 'Unknown';

    return {
      id: apiApproval.id,
      title: apiApproval.title,
      description: apiApproval.description || '',
      amount: apiApproval.amount,
      category: apiApproval.category,
      requestedBy: requestedByName,
      requestedAt: apiApproval.createdAt,
      status: apiApproval.status.toLowerCase() as 'pending' | 'approved' | 'rejected',
      priority: apiApproval.priority.toLowerCase() as 'low' | 'normal' | 'high' | 'urgent',
      vendor: apiApproval.vendor?.companyName,
      attachments: apiApproval.attachments?.map(a => a.url),
    };
  };

  const fetchApprovals = useCallback(async () => {
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
        `${API_BASE_URL}/approvals/household/${householdInfo.id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch approvals: ${response.status}`);
      }

      const apiApprovals: ApprovalFromAPI[] = await response.json();
      const convertedApprovals = apiApprovals.map(convertApproval);
      setApprovals(convertedApprovals);
      setError(null);
    } catch (err) {
      console.error('Fetch approvals error:', err);
      setError('Failed to load approvals. Please try again.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchApprovals();
  }, [fetchApprovals]);

  const handleApprove = async (id: string) => {
    Alert.alert(
      'Approve Request',
      'Are you sure you want to approve this request?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Approve',
          onPress: async () => {
            setIsProcessing(id);
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired. Please sign in again.');
                return;
              }

              const response = await fetch(`${API_BASE_URL}/approvals/${id}/decide`, {
                method: 'PATCH',
                headers: {
                  Authorization: `Bearer ${token}`,
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                  status: 'APPROVED',
                  decisionNote: '',
                }),
              });

              if (!response.ok) {
                throw new Error('Failed to approve request');
              }

              // Update local state
              setApprovals(prev =>
                prev.map(a => (a.id === id ? { ...a, status: 'approved' as const } : a))
              );
            } catch (err) {
              console.error('Approve error:', err);
              Alert.alert('Error', 'Failed to approve request. Please try again.');
            } finally {
              setIsProcessing(null);
            }
          },
        },
      ]
    );
  };

  const handleReject = async (id: string) => {
    Alert.alert(
      'Reject Request',
      'Are you sure you want to reject this request?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reject',
          style: 'destructive',
          onPress: async () => {
            setIsProcessing(id);
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired. Please sign in again.');
                return;
              }

              const response = await fetch(`${API_BASE_URL}/approvals/${id}/decide`, {
                method: 'PATCH',
                headers: {
                  Authorization: `Bearer ${token}`,
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                  status: 'REJECTED',
                  decisionNote: '',
                }),
              });

              if (!response.ok) {
                throw new Error('Failed to reject request');
              }

              // Update local state
              setApprovals(prev =>
                prev.map(a => (a.id === id ? { ...a, status: 'rejected' as const } : a))
              );
            } catch (err) {
              console.error('Reject error:', err);
              Alert.alert('Error', 'Failed to reject request. Please try again.');
            } finally {
              setIsProcessing(null);
            }
          },
        },
      ]
    );
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const filteredApprovals = approvals.filter(a =>
    filter === 'all' ? true : a.status === 'pending'
  );

  const pendingCount = approvals.filter(a => a.status === 'pending').length;

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent':
        return colors.status.error;
      case 'high':
        return colors.haven.champagne[600];
      case 'normal':
        return colors.haven.navy[600];
      default:
        return colors.text.tertiary;
    }
  };

  const handleApprovalPress = (approvalId: string) => {
    router.push(`/(tabs)/approvals/${approvalId}` as any);
  };

  const renderApproval = ({ item }: { item: Approval }) => {
    const isProcessingThis = isProcessing === item.id;

    return (
      <TouchableOpacity activeOpacity={0.7} onPress={() => handleApprovalPress(item.id)}>
      <Card style={styles.approvalCard}>
        <View style={styles.approvalHeader}>
          <View style={styles.approvalInfo}>
            <View style={styles.titleRow}>
              <Text style={styles.approvalTitle}>{item.title}</Text>
              {item.priority !== 'normal' && item.priority !== 'low' && (
                <View
                  style={[
                    styles.priorityBadge,
                    { backgroundColor: getPriorityColor(item.priority) },
                  ]}
                >
                  <Text style={styles.priorityText}>
                    {item.priority.toUpperCase()}
                  </Text>
                </View>
              )}
            </View>
            {item.vendor && <Text style={styles.approvalVendor}>{item.vendor}</Text>}
          </View>
          <Text style={styles.approvalAmount}>{formatCurrency(item.amount)}</Text>
        </View>

        {item.description && (
          <Text style={styles.approvalDescription}>{item.description}</Text>
        )}

        <View style={styles.approvalMeta}>
          <View style={styles.metaItem}>
            <Ionicons name="person-outline" size={14} color={colors.text.tertiary} />
            <Text style={styles.metaText}>{item.requestedBy}</Text>
          </View>
          <View style={styles.metaItem}>
            <Ionicons name="time-outline" size={14} color={colors.text.tertiary} />
            <Text style={styles.metaText}>{formatDate(item.requestedAt)}</Text>
          </View>
        </View>

        {item.status === 'pending' ? (
          <View style={styles.approvalActions}>
            <Button
              title="Reject"
              variant="outline"
              onPress={() => handleReject(item.id)}
              style={styles.rejectButton}
              disabled={isProcessingThis}
            />
            <Button
              title={isProcessingThis ? 'Processing...' : 'Approve'}
              onPress={() => handleApprove(item.id)}
              style={styles.approveButton}
              disabled={isProcessingThis}
            />
          </View>
        ) : (
          <View style={styles.statusContainer}>
            <Badge
              label={item.status === 'approved' ? 'Approved' : 'Rejected'}
              variant={item.status === 'approved' ? 'success' : 'error'}
            />
          </View>
        )}
      </Card>
      </TouchableOpacity>
    );
  };

  if (isLoading) {
    return (
      <ScreenContainer title="Approvals" onBackPress={() => router.navigate('/more')}>
        <LoadingSpinner fullScreen message="Loading approvals..." />
      </ScreenContainer>
    );
  }

  if (error && approvals.length === 0) {
    return (
      <ScreenContainer title="Approvals" onBackPress={() => router.navigate('/more')}>
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Approvals</Text>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchApprovals}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer title="Approvals" onBackPress={() => router.navigate('/more')} scrollable={false}>
      {/* Filter Tabs */}
      <View style={styles.filterContainer}>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'pending' && styles.filterTabActive]}
          onPress={() => setFilter('pending')}
        >
          <Text style={[styles.filterText, filter === 'pending' && styles.filterTextActive]}>
            Pending
          </Text>
          {pendingCount > 0 && (
            <View style={styles.filterBadge}>
              <Text style={styles.filterBadgeText}>{pendingCount}</Text>
            </View>
          )}
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'all' && styles.filterTabActive]}
          onPress={() => setFilter('all')}
        >
          <Text style={[styles.filterText, filter === 'all' && styles.filterTextActive]}>
            All
          </Text>
        </TouchableOpacity>
      </View>

      {/* Approvals List */}
      <FlatList
        data={filteredApprovals}
        renderItem={renderApproval}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        style={styles.listContainer}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchApprovals();
            }}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="checkmark-circle" size={48} color={colors.haven.navy[300]} />
            <Text style={styles.emptyTitle}>All caught up!</Text>
            <Text style={styles.emptyText}>
              {filter === 'pending' ? 'No pending approvals' : 'No approvals yet'}
            </Text>
          </View>
        }
      />
    </ScreenContainer>
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
  listContainer: {
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
  approvalCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  approvalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[2],
  },
  approvalInfo: {
    flex: 1,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  approvalTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  priorityBadge: {
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
  },
  priorityText: {
    fontSize: 11,  // Minimum for badges
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },
  approvalVendor: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    marginTop: 2,
  },
  approvalAmount: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  approvalDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[3],
    lineHeight: 20,
  },
  approvalMeta: {
    flexDirection: 'row',
    gap: spacing[4],
    marginBottom: spacing[3],
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
  approvalActions: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  rejectButton: {
    flex: 1,
  },
  approveButton: {
    flex: 1,
  },
  statusContainer: {
    alignItems: 'flex-start',
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
  },
});
