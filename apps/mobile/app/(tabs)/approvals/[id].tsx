import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
  Linking,
  Image,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as WebBrowser from 'expo-web-browser';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Badge, Button, LoadingSpinner } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

interface Attachment {
  id: string;
  url: string;
  filename: string;
  mimeType?: string;
}

interface ApprovalDetail {
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
    email?: string | null;
  };
  decidedBy?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
  } | null;
  vendor?: {
    id: string;
    companyName: string;
    phone?: string | null;
    email?: string | null;
  } | null;
  attachments?: Attachment[];
}

export default function ApprovalDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo, user } = useAuth();
  const [approval, setApproval] = useState<ApprovalDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchApproval = useCallback(async () => {
    if (!id) return;

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(`${API_BASE_URL}/approvals/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch approval: ${response.status}`);
      }

      const data: ApprovalDetail = await response.json();
      setApproval(data);
      setError(null);
    } catch (err) {
      console.error('Fetch approval error:', err);
      setError('Failed to load approval details.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id]);

  useEffect(() => {
    fetchApproval();
  }, [fetchApproval]);

  const handleApprove = async () => {
    Alert.alert(
      'Approve Request',
      'Are you sure you want to approve this request?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Approve',
          onPress: async () => {
            setIsProcessing(true);
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired.');
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

              if (!response.ok) throw new Error('Failed to approve');

              Alert.alert('Approved', 'Request has been approved.');
              fetchApproval();
            } catch (err) {
              Alert.alert('Error', 'Failed to approve request.');
            } finally {
              setIsProcessing(false);
            }
          },
        },
      ]
    );
  };

  const handleReject = async () => {
    Alert.alert(
      'Reject Request',
      'Are you sure you want to reject this request?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reject',
          style: 'destructive',
          onPress: async () => {
            setIsProcessing(true);
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired.');
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

              if (!response.ok) throw new Error('Failed to reject');

              Alert.alert('Rejected', 'Request has been rejected.');
              fetchApproval();
            } catch (err) {
              Alert.alert('Error', 'Failed to reject request.');
            } finally {
              setIsProcessing(false);
            }
          },
        },
      ]
    );
  };

  const handleViewAttachment = async (attachment: Attachment) => {
    try {
      await WebBrowser.openBrowserAsync(attachment.url);
    } catch (err) {
      Alert.alert('Error', 'Could not open attachment.');
    }
  };

  const handleCallVendor = () => {
    if (approval?.vendor?.phone) {
      Linking.openURL(`tel:${approval.vendor.phone}`);
    }
  };

  const handleEmailVendor = () => {
    if (approval?.vendor?.email) {
      Linking.openURL(`mailto:${approval.vendor.email}`);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const formatDateTime = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'URGENT':
        return colors.status.error;
      case 'HIGH':
        return colors.haven.champagne[600];
      case 'NORMAL':
        return colors.haven.navy[600];
      default:
        return colors.text.tertiary;
    }
  };

  const getStatusVariant = (status: string): 'success' | 'error' | 'warning' => {
    switch (status) {
      case 'APPROVED':
        return 'success';
      case 'REJECTED':
        return 'error';
      default:
        return 'warning';
    }
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading approval..." />;
  }

  if (error || !approval) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Approval' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Approval</Text>
          <Text style={styles.errorText}>{error || 'Approval not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchApproval}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const requestedByName = approval.requestedBy
    ? `${approval.requestedBy.firstName || ''} ${approval.requestedBy.lastName || ''}`.trim() || 'Unknown'
    : 'Unknown';

  const decidedByName = approval.decidedBy
    ? `${approval.decidedBy.firstName || ''} ${approval.decidedBy.lastName || ''}`.trim()
    : null;

  const isPending = approval.status === 'PENDING';

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: 'Approval Request' }} />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchApproval();
            }}
          />
        }
      >
        {/* Header Card */}
        <Card style={styles.headerCard}>
          <View style={styles.headerTop}>
            <View style={styles.titleContainer}>
              <Text style={styles.title}>{approval.title}</Text>
              {approval.priority !== 'NORMAL' && approval.priority !== 'LOW' && (
                <View
                  style={[
                    styles.priorityBadge,
                    { backgroundColor: getPriorityColor(approval.priority) },
                  ]}
                >
                  <Text style={styles.priorityText}>{approval.priority}</Text>
                </View>
              )}
            </View>
            <Text style={styles.amount}>{formatCurrency(approval.amount)}</Text>
          </View>

          <View style={styles.badgeRow}>
            <Badge label={approval.category} variant="default" />
            <Badge label={approval.status} variant={getStatusVariant(approval.status)} />
          </View>

          {approval.description && (
            <Text style={styles.description}>{approval.description}</Text>
          )}
        </Card>

        {/* Request Info */}
        <Card style={styles.section}>
          <Text style={styles.sectionTitle}>Request Details</Text>

          <View style={styles.detailRow}>
            <Ionicons name="person-outline" size={18} color={colors.text.tertiary} />
            <View style={styles.detailContent}>
              <Text style={styles.detailLabel}>Requested By</Text>
              <Text style={styles.detailValue}>{requestedByName}</Text>
              <Text style={styles.detailSubtext}>{approval.requestedBy.role}</Text>
            </View>
          </View>

          <View style={styles.detailRow}>
            <Ionicons name="time-outline" size={18} color={colors.text.tertiary} />
            <View style={styles.detailContent}>
              <Text style={styles.detailLabel}>Submitted</Text>
              <Text style={styles.detailValue}>{formatDateTime(approval.createdAt)}</Text>
            </View>
          </View>

          {approval.dueDate && (
            <View style={styles.detailRow}>
              <Ionicons name="calendar-outline" size={18} color={colors.text.tertiary} />
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Due Date</Text>
                <Text style={styles.detailValue}>{formatDate(approval.dueDate)}</Text>
              </View>
            </View>
          )}
        </Card>

        {/* Decision Info (if decided) */}
        {!isPending && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Decision</Text>

            {decidedByName && (
              <View style={styles.detailRow}>
                <Ionicons name="checkmark-circle-outline" size={18} color={colors.text.tertiary} />
                <View style={styles.detailContent}>
                  <Text style={styles.detailLabel}>Decided By</Text>
                  <Text style={styles.detailValue}>{decidedByName}</Text>
                </View>
              </View>
            )}

            {approval.decidedAt && (
              <View style={styles.detailRow}>
                <Ionicons name="time-outline" size={18} color={colors.text.tertiary} />
                <View style={styles.detailContent}>
                  <Text style={styles.detailLabel}>Decision Date</Text>
                  <Text style={styles.detailValue}>{formatDateTime(approval.decidedAt)}</Text>
                </View>
              </View>
            )}

            {approval.decisionNote && (
              <View style={styles.noteContainer}>
                <Text style={styles.noteLabel}>Note</Text>
                <Text style={styles.noteText}>{approval.decisionNote}</Text>
              </View>
            )}
          </Card>
        )}

        {/* Vendor Info */}
        {approval.vendor && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Vendor</Text>

            <View style={styles.vendorHeader}>
              <View style={styles.vendorIcon}>
                <Ionicons name="business" size={24} color={colors.haven.champagne[500]} />
              </View>
              <Text style={styles.vendorName}>{approval.vendor.companyName}</Text>
            </View>

            {(approval.vendor.phone || approval.vendor.email) && (
              <View style={styles.vendorActions}>
                {approval.vendor.phone && (
                  <TouchableOpacity style={styles.vendorAction} onPress={handleCallVendor}>
                    <Ionicons name="call" size={20} color={colors.haven.champagne[500]} />
                    <Text style={styles.vendorActionText}>Call</Text>
                  </TouchableOpacity>
                )}
                {approval.vendor.email && (
                  <TouchableOpacity style={styles.vendorAction} onPress={handleEmailVendor}>
                    <Ionicons name="mail" size={20} color={colors.haven.champagne[500]} />
                    <Text style={styles.vendorActionText}>Email</Text>
                  </TouchableOpacity>
                )}
              </View>
            )}
          </Card>
        )}

        {/* Attachments */}
        {approval.attachments && approval.attachments.length > 0 && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Attachments</Text>
            {approval.attachments.map((attachment) => (
              <TouchableOpacity
                key={attachment.id}
                style={styles.attachmentItem}
                onPress={() => handleViewAttachment(attachment)}
              >
                <Ionicons name="document-outline" size={20} color={colors.haven.champagne[500]} />
                <Text style={styles.attachmentName}>{attachment.filename}</Text>
                <Ionicons name="open-outline" size={18} color={colors.text.tertiary} />
              </TouchableOpacity>
            ))}
          </Card>
        )}

        {/* Action Buttons (if pending) */}
        {isPending && (
          <View style={styles.actionButtons}>
            <Button
              title="Reject"
              variant="outline"
              onPress={handleReject}
              style={styles.rejectButton}
              disabled={isProcessing}
            />
            <Button
              title={isProcessing ? 'Processing...' : 'Approve'}
              onPress={handleApprove}
              style={styles.approveButton}
              disabled={isProcessing}
            />
          </View>
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
    paddingBottom: spacing[8],
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
  headerCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[3],
  },
  titleContainer: {
    flex: 1,
    marginRight: spacing[3],
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  priorityBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
    marginTop: spacing[1],
  },
  priorityText: {
    fontSize: 11,  // Minimum for badges
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },
  amount: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  badgeRow: {
    flexDirection: 'row',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  description: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    lineHeight: 22,
  },
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[3],
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
    gap: spacing[3],
  },
  detailContent: {
    flex: 1,
  },
  detailLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  detailValue: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  detailSubtext: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  noteContainer: {
    marginTop: spacing[3],
    padding: spacing[3],
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.lg,
  },
  noteLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: spacing[1],
  },
  noteText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    lineHeight: 20,
  },
  vendorHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    marginBottom: spacing[3],
  },
  vendorIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  vendorName: {
    flex: 1,
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  vendorActions: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  vendorAction: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.champagne[50],
    borderRadius: borderRadius.lg,
  },
  vendorActionText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[600],
  },
  attachmentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  attachmentName: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
  },
  actionButtons: {
    flexDirection: 'row',
    gap: spacing[3],
    marginTop: spacing[4],
  },
  rejectButton: {
    flex: 1,
  },
  approveButton: {
    flex: 1,
  },
});
