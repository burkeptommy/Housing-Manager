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
import { useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

interface Request {
  id: string;
  subject: string;
  status: string;
  createdAt: string;
  lastMessageAt?: string;
  unreadCount?: number;
}

export default function RequestsScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [requests, setRequests] = useState<Request[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [filter, setFilter] = useState<'active' | 'all'>('active');
  const [error, setError] = useState<string | null>(null);

  const fetchRequests = useCallback(async () => {
    if (!householdInfo?.id) {
      setError('No household found.');
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(`${API_BASE_URL}/conversations`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch requests');
      }

      const data: Request[] = await response.json();
      setRequests(data);
      setError(null);
    } catch (err) {
      console.error('Fetch requests error:', err);
      setError('Failed to load requests.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'default' => {
    switch (status) {
      case 'OPEN':
      case 'PENDING':
        return 'warning';
      case 'RESOLVED':
      case 'CLOSED':
        return 'success';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status: string): string => {
    switch (status) {
      case 'OPEN':
        return 'Open';
      case 'PENDING':
        return 'Pending';
      case 'RESOLVED':
        return 'Resolved';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
    } else if (diffDays === 1) {
      return 'Yesterday';
    } else if (diffDays < 7) {
      return date.toLocaleDateString('en-US', { weekday: 'short' });
    } else {
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
  };

  const filteredRequests = requests.filter(r =>
    filter === 'active' ? r.status === 'OPEN' || r.status === 'PENDING' : true
  );

  const renderRequest = ({ item }: { item: Request }) => (
    <TouchableOpacity
      activeOpacity={0.7}
      onPress={() => router.push(`/(tabs)/sarah/chat` as any)}
    >
      <Card style={styles.requestCard}>
        <View style={styles.requestHeader}>
          <Text style={styles.requestSubject} numberOfLines={1}>{item.subject}</Text>
          <Badge label={getStatusLabel(item.status)} variant={getStatusVariant(item.status)} size="sm" />
        </View>
        <View style={styles.requestMeta}>
          <Ionicons name="time-outline" size={14} color={colors.text.tertiary} />
          <Text style={styles.requestDate}>{formatDate(item.createdAt)}</Text>
          {item.unreadCount && item.unreadCount > 0 && (
            <View style={styles.unreadBadge}>
              <Text style={styles.unreadText}>{item.unreadCount}</Text>
            </View>
          )}
        </View>
      </Card>
    </TouchableOpacity>
  );

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading requests..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: 'All Requests' }} />

      {/* Filter Tabs */}
      <View style={styles.filterContainer}>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'active' && styles.filterTabActive]}
          onPress={() => setFilter('active')}
        >
          <Text style={[styles.filterText, filter === 'active' && styles.filterTextActive]}>
            Active
          </Text>
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

      <FlatList
        data={filteredRequests}
        renderItem={renderRequest}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchRequests();
            }}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="chatbubbles-outline" size={48} color={colors.haven.purple[300]} />
            <Text style={styles.emptyTitle}>No requests</Text>
            <Text style={styles.emptyText}>
              {filter === 'active' ? 'No active requests' : 'No requests yet'}
            </Text>
          </View>
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  filterContainer: {
    flexDirection: 'row',
    padding: spacing[4],
    gap: spacing[2],
  },
  filterTab: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
  },
  filterTabActive: {
    backgroundColor: colors.haven.purple[900],
  },
  filterText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  filterTextActive: {
    color: colors.white,
  },
  listContent: {
    padding: spacing[4],
    paddingTop: 0,
  },
  requestCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  requestHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  requestSubject: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginRight: spacing[2],
  },
  requestMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  requestDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  unreadBadge: {
    backgroundColor: colors.status.error,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
    marginLeft: spacing[2],
  },
  unreadText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
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
