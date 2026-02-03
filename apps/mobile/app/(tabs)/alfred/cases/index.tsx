import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../../src/components/ScreenContainer';
import { colors, spacing, typography, borderRadius } from '../../../../src/lib/theme';
import { getIdToken } from '../../../../src/lib/firebase';

const API_URL = process.env.EXPO_PUBLIC_API_URL;

interface EmailCase {
  id: string;
  caseNumber: string;
  subject: string;
  fromEmail: string;
  receivedAt: string;
  status: string;
  summary?: string;
}

export default function CasesListScreen() {
  const [cases, setCases] = useState<EmailCase[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [filter, setFilter] = useState<'all' | 'active' | 'completed'>('all');

  const fetchCases = useCallback(async () => {
    try {
      const token = await getIdToken();
      if (!token) return;
      const response = await fetch(`${API_URL}/alfred/cases`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (response.ok) {
        const data = await response.json();
        setCases(data);
      }
    } catch (error) {
      console.error('Failed to fetch cases:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchCases();
  }, [fetchCases]);

  const onRefresh = () => {
    setIsRefreshing(true);
    fetchCases();
  };

  const filteredCases = cases.filter((c) => {
    if (filter === 'all') return true;
    if (filter === 'active') return c.status === 'AWAITING_INPUT' || c.status === 'PROCESSING';
    if (filter === 'completed') return c.status === 'COMPLETED';
    return true;
  });

  const activeCount = cases.filter(
    (c) => c.status === 'AWAITING_INPUT' || c.status === 'PROCESSING',
  ).length;

  const renderCase = ({ item }: { item: EmailCase }) => {
    const isActive = item.status === 'AWAITING_INPUT' || item.status === 'PROCESSING';

    return (
      <TouchableOpacity
        style={styles.caseCard}
        onPress={() => router.push(`/(tabs)/alfred/cases/${item.id}` as any)}
      >
        <View style={styles.caseHeader}>
          <View
            style={[styles.statusDot, isActive ? styles.statusActive : styles.statusCompleted]}
          />
          <Text style={styles.caseNumber}>{item.caseNumber}</Text>
          <Text style={styles.caseDate}>
            {new Date(item.receivedAt).toLocaleDateString('en-US', {
              month: 'short',
              day: 'numeric',
            })}
          </Text>
        </View>
        <Text style={styles.caseSubject} numberOfLines={2}>
          {item.subject}
        </Text>
        {isActive && (
          <View style={styles.actionNeeded}>
            <Ionicons name="chatbubble" size={14} color={colors.haven.sage[600]} />
            <Text style={styles.actionNeededText}>Alfred needs your input</Text>
          </View>
        )}
      </TouchableOpacity>
    );
  };

  const simulateEmail = async (scenario: string) => {
    try {
      const token = await getIdToken();
      if (!token) return;
      const res = await fetch(`${API_URL}/alfred/test/simulate-email`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ scenario }),
      });
      if (res.ok) {
        Alert.alert('Test Email Sent', `Simulated "${scenario.replace(/_/g, ' ')}" email. Pull to refresh to see the case.`);
        fetchCases();
      } else {
        const err = await res.json().catch(() => ({}));
        Alert.alert('Error', err.message || 'Failed to simulate email');
      }
    } catch (err) {
      Alert.alert('Error', 'Could not reach the server');
    }
  };

  if (isLoading) {
    return (
      <ScreenContainer title="Email Cases" showBack>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.sage[500]} />
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer title="Email Cases" showBack>
      {/* Filter Tabs */}
      <View style={styles.filterContainer}>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'all' && styles.filterTabActive]}
          onPress={() => setFilter('all')}
        >
          <Text style={[styles.filterText, filter === 'all' && styles.filterTextActive]}>
            All ({cases.length})
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'active' && styles.filterTabActive]}
          onPress={() => setFilter('active')}
        >
          <Text style={[styles.filterText, filter === 'active' && styles.filterTextActive]}>
            Needs Action ({activeCount})
          </Text>
          {activeCount > 0 && (
            <View style={styles.filterBadge}>
              <Text style={styles.filterBadgeText}>{activeCount}</Text>
            </View>
          )}
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'completed' && styles.filterTabActive]}
          onPress={() => setFilter('completed')}
        >
          <Text style={[styles.filterText, filter === 'completed' && styles.filterTextActive]}>
            Done
          </Text>
        </TouchableOpacity>
      </View>

      {/* Cases List */}
      <FlatList
        data={filteredCases}
        keyExtractor={(item) => item.id}
        renderItem={renderCase}
        contentContainerStyle={styles.listContent}
        refreshControl={<RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="mail-open-outline" size={48} color={colors.haven.navy[300]} />
            <Text style={styles.emptyTitle}>No emails yet</Text>
            <Text style={styles.emptyText}>
              Forward or CC Alfred on any email and it'll show up here.
            </Text>
          </View>
        }
        ListFooterComponent={
          __DEV__ ? (
            <View style={styles.debugSection}>
              <Text style={styles.debugTitle}>Test Scenarios</Text>
              <Text style={styles.debugSubtext}>Dev only - simulate inbound emails</Text>
              {[
                { key: 'camp_registration', label: 'Camp Registration' },
                { key: 'utility_bill', label: 'Utility Bill' },
                { key: 'vendor_quote', label: 'Vendor Quote' },
                { key: 'appointment', label: 'Appointment' },
                { key: 'school_event', label: 'School Event' },
                { key: 'home_inspection', label: 'Home Inspection' },
              ].map((scenario) => (
                <TouchableOpacity
                  key={scenario.key}
                  style={styles.debugButton}
                  onPress={() => simulateEmail(scenario.key)}
                >
                  <Ionicons name="flask-outline" size={16} color={colors.haven.navy[600]} />
                  <Text style={styles.debugButtonText}>{scenario.label}</Text>
                </TouchableOpacity>
              ))}
            </View>
          ) : null
        }
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  filterContainer: {
    flexDirection: 'row',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    gap: spacing[2],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.default,
  },
  filterTab: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    gap: spacing[1],
  },
  filterTabActive: {
    backgroundColor: colors.haven.navy[100],
  },
  filterText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
  },
  filterTextActive: {
    color: colors.haven.navy[900],
    fontWeight: typography.fontWeights.medium as '500',
  },
  filterBadge: {
    backgroundColor: colors.haven.sage[500],
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 10,
  },
  filterBadgeText: {
    color: colors.white,
    fontSize: 10,
    fontWeight: typography.fontWeights.bold as '700',
  },
  listContent: {
    padding: spacing[4],
    gap: spacing[3],
  },
  caseCard: {
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  caseHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: spacing[2],
  },
  statusActive: {
    backgroundColor: colors.haven.sage[500],
  },
  statusCompleted: {
    backgroundColor: colors.haven.navy[300],
  },
  caseNumber: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    fontFamily: 'monospace',
  },
  caseDate: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[400],
  },
  caseSubject: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium as '500',
    color: colors.haven.navy[900],
    marginBottom: spacing[2],
  },
  actionNeeded: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  actionNeededText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.sage[600],
    fontWeight: typography.fontWeights.medium as '500',
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing[12],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold as '600',
    color: colors.haven.navy[700],
    marginTop: spacing[4],
    marginBottom: spacing[2],
  },
  emptyText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[500],
    textAlign: 'center',
    paddingHorizontal: spacing[8],
  },

  // Debug section
  debugSection: {
    marginTop: spacing[6],
    padding: spacing[4],
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.slate[200],
    borderStyle: 'dashed',
  },
  debugTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold as '600',
    color: colors.slate[600],
    marginBottom: 2,
  },
  debugSubtext: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginBottom: spacing[3],
  },
  debugButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.white,
    borderRadius: borderRadius.md,
    marginBottom: spacing[2],
    borderWidth: 1,
    borderColor: colors.slate[200],
  },
  debugButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[700],
  },
});
