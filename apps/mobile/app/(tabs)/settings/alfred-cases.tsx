import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { AppHeader, Badge } from '../../../src/components';
import {
  colors,
  spacing,
  typography,
  borderRadius,
} from '../../../src/lib/theme';
import { getIdToken } from '../../../src/lib/firebase';
import { API_BASE_URL } from '../../../src/lib/api';

interface EmailCase {
  id: string;
  caseNumber: string;
  fromEmail: string;
  subject: string;
  status: 'RECEIVED' | 'PROCESSING' | 'AWAITING_INPUT' | 'IN_PROGRESS' | 'COMPLETED' | 'ARCHIVED';
  priority: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
  summary: string | null;
  detectedIntent: string | null;
  receivedAt: string;
  attachments: { id: string; filename: string }[];
}

const statusConfig: Record<string, { label: string; variant: 'default' | 'success' | 'warning' | 'error' | 'info' }> = {
  RECEIVED: { label: 'Received', variant: 'info' },
  PROCESSING: { label: 'Processing', variant: 'info' },
  AWAITING_INPUT: { label: 'Needs Input', variant: 'warning' },
  IN_PROGRESS: { label: 'In Progress', variant: 'info' },
  COMPLETED: { label: 'Completed', variant: 'success' },
  ARCHIVED: { label: 'Archived', variant: 'default' },
};

const priorityConfig: Record<string, { color: string; icon: string }> = {
  LOW: { color: colors.text.tertiary, icon: 'chevron-down' },
  NORMAL: { color: colors.text.secondary, icon: 'remove' },
  HIGH: { color: colors.status.warning, icon: 'chevron-up' },
  URGENT: { color: colors.status.error, icon: 'alert-circle' },
};

export default function AlfredCasesScreen() {
  const router = useRouter();
  const [cases, setCases] = useState<EmailCase[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [filterStatus, setFilterStatus] = useState<string | null>(null);

  const fetchCases = useCallback(async () => {
    try {
      const token = await getIdToken();
      const url = filterStatus
        ? `${API_BASE_URL}/alfred/cases?status=${filterStatus}`
        : `${API_BASE_URL}/alfred/cases`;

      const response = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });

      const data = await response.json();
      setCases(Array.isArray(data) ? data : []);
    } catch (err) {
      console.error('Failed to fetch cases:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [filterStatus]);

  useEffect(() => {
    fetchCases();
  }, [fetchCases]);

  const onRefresh = () => {
    setIsRefreshing(true);
    fetchCases();
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffHours < 1) return 'Just now';
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;

    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
    });
  };

  const getCategoryIcon = (intent: string | null): string => {
    if (!intent) return 'mail-outline';

    const intentLower = intent.toLowerCase();
    if (intentLower.includes('calendar') || intentLower.includes('event') || intentLower.includes('schedule'))
      return 'calendar-outline';
    if (intentLower.includes('bill') || intentLower.includes('invoice') || intentLower.includes('payment'))
      return 'card-outline';
    if (intentLower.includes('vendor') || intentLower.includes('service'))
      return 'business-outline';
    if (intentLower.includes('shipping') || intentLower.includes('delivery'))
      return 'cube-outline';
    if (intentLower.includes('warranty'))
      return 'shield-checkmark-outline';
    if (intentLower.includes('hoa'))
      return 'home-outline';
    if (intentLower.includes('school') || intentLower.includes('camp'))
      return 'school-outline';
    if (intentLower.includes('medical') || intentLower.includes('prescription'))
      return 'medkit-outline';

    return 'mail-outline';
  };

  const renderCase = ({ item }: { item: EmailCase }) => {
    const status = statusConfig[item.status] || statusConfig.RECEIVED;
    const priority = priorityConfig[item.priority] || priorityConfig.NORMAL;

    return (
      <TouchableOpacity
        style={styles.caseCard}
        onPress={() => router.push(`/(tabs)/settings/alfred-case/${item.id}` as any)}
      >
        <View style={styles.caseHeader}>
          <View style={[styles.iconContainer, { backgroundColor: `${colors.haven.champagne[500]}15` }]}>
            <Ionicons
              name={getCategoryIcon(item.detectedIntent) as any}
              size={24}
              color={colors.haven.champagne[500]}
            />
          </View>
          <View style={styles.caseInfo}>
            <Text style={styles.caseSubject} numberOfLines={1}>
              {item.subject}
            </Text>
            <Text style={styles.caseFrom} numberOfLines={1}>
              {item.fromEmail}
            </Text>
          </View>
          <View style={styles.caseMetaRight}>
            <Text style={styles.caseTime}>{formatDate(item.receivedAt)}</Text>
            {item.priority !== 'NORMAL' && (
              <Ionicons
                name={priority.icon as any}
                size={16}
                color={priority.color}
                style={styles.priorityIcon}
              />
            )}
          </View>
        </View>

        {item.summary && (
          <Text style={styles.caseSummary} numberOfLines={2}>
            {item.summary}
          </Text>
        )}

        <View style={styles.caseFooter}>
          <Badge label={status.label} variant={status.variant} size="sm" />
          {item.attachments.length > 0 && (
            <View style={styles.attachmentBadge}>
              <Ionicons name="attach" size={14} color={colors.text.tertiary} />
              <Text style={styles.attachmentCount}>{item.attachments.length}</Text>
            </View>
          )}
          <Text style={styles.caseNumber}>#{item.caseNumber}</Text>
        </View>
      </TouchableOpacity>
    );
  };

  const FilterChip = ({ label, value }: { label: string; value: string | null }) => {
    const isActive = filterStatus === value;
    return (
      <TouchableOpacity
        style={[styles.filterChip, isActive && styles.filterChipActive]}
        onPress={() => setFilterStatus(value)}
      >
        <Text style={[styles.filterChipText, isActive && styles.filterChipTextActive]}>
          {label}
        </Text>
      </TouchableOpacity>
    );
  };

  if (isLoading) {
    return (
      <View style={styles.fullContainer}>
        <AppHeader
          title="Email History"
          showBack
          onBackPress={() => router.navigate('/(tabs)/settings/alfred-email' as any)}
        />
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.champagne[500]} />
        </View>
      </View>
    );
  }

  return (
    <View style={styles.fullContainer}>
      <AppHeader
        title="Email History"
        showBack
        onBackPress={() => router.navigate('/(tabs)/settings/alfred-email' as any)}
      />

      {/* Filter chips */}
      <View style={styles.filterContainer}>
        <FilterChip label="All" value={null} />
        <FilterChip label="Needs Input" value="AWAITING_INPUT" />
        <FilterChip label="In Progress" value="IN_PROGRESS" />
        <FilterChip label="Completed" value="COMPLETED" />
      </View>

      <FlatList
        data={cases}
        renderItem={renderCase}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={onRefresh}
            tintColor={colors.haven.champagne[500]}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="mail-unread-outline" size={64} color={colors.text.tertiary} />
            <Text style={styles.emptyTitle}>No emails yet</Text>
            <Text style={styles.emptyText}>
              CC Alfred on your emails and they'll appear here
            </Text>
          </View>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  fullContainer: {
    flex: 1,
    backgroundColor: colors.haven.navy[900],
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background.secondary,
  },
  filterContainer: {
    flexDirection: 'row',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    backgroundColor: colors.background.secondary,
    gap: spacing[2],
  },
  filterChip: {
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
    backgroundColor: colors.gray[200],
  },
  filterChipActive: {
    backgroundColor: colors.haven.champagne[500],
  },
  filterChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  filterChipTextActive: {
    color: colors.white,
  },
  listContent: {
    padding: spacing[4],
    backgroundColor: colors.background.secondary,
    flexGrow: 1,
  },
  caseCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[3],
    shadowColor: colors.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  caseHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconContainer: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.lg,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing[3],
  },
  caseInfo: {
    flex: 1,
  },
  caseSubject: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  caseFrom: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  caseMetaRight: {
    alignItems: 'flex-end',
  },
  caseTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  priorityIcon: {
    marginTop: 4,
  },
  caseSummary: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[3],
    lineHeight: 20,
  },
  caseFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[2],
  },
  attachmentBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  attachmentCount: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  caseNumber: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginLeft: 'auto',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: spacing[16],
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
    paddingHorizontal: spacing[8],
  },
});
