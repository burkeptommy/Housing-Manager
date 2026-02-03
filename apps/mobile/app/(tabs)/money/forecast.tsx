import { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../src/components/ScreenContainer';
import { colors, spacing, typography, borderRadius, shadows } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

interface SystemForecast {
  id: string;
  systemType: string;
  systemName: string;
  installYear: number | null;
  typicalLifespan: number | null;
  estimatedAge: number | null;
  remainingYears: number | null;
  expectedReplacementYear: number | null;
  estimatedReplacementCost: number | null;
  urgency: string | null;
  notes: string | null;
  alfredResearchData: unknown;
}

interface ForecastData {
  forecasts: SystemForecast[];
  summary: {
    totalSystems: number;
    urgentCount: number;
    totalUpcomingCost: number;
  };
}

interface TimelineYear {
  year: number;
  items: Array<{
    systemName: string;
    cost: number;
    urgency: string;
  }>;
  totalCost: number;
}

function formatCurrency(amount: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

function getUrgencyColor(urgency: string | null) {
  switch (urgency) {
    case 'CRITICAL':
      return colors.status.error;
    case 'HIGH':
      return colors.status.warning;
    case 'MEDIUM':
      return '#FB8C00';
    case 'LOW':
      return colors.haven.sage[500];
    default:
      return colors.slate[400];
  }
}

function getUrgencyLabel(urgency: string | null) {
  switch (urgency) {
    case 'CRITICAL':
      return 'Replace Soon';
    case 'HIGH':
      return 'Plan Ahead';
    case 'MEDIUM':
      return 'Monitor';
    case 'LOW':
      return 'Good Shape';
    default:
      return 'Unknown';
  }
}

export default function ForecastScreen() {
  const router = useRouter();
  const [data, setData] = useState<ForecastData | null>(null);
  const [timeline, setTimeline] = useState<TimelineYear[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [fetchError, setFetchError] = useState(false);
  const [activeTab, setActiveTab] = useState<'systems' | 'timeline'>('systems');

  const fetchData = useCallback(async () => {
    try {
      setFetchError(false);
      const token = await getIdToken(true);
      if (!token) return;

      const [forecastRes, timelineRes] = await Promise.all([
        fetch(`${API_BASE_URL}/budgeting/forecast`, {
          headers: { Authorization: `Bearer ${token}` },
        }).catch(() => null),
        fetch(`${API_BASE_URL}/budgeting/forecast/timeline?years=10`, {
          headers: { Authorization: `Bearer ${token}` },
        }).catch(() => null),
      ]);

      if (forecastRes?.ok) setData(await forecastRes.json());
      if (timelineRes?.ok) setTimeline(await timelineRes.json());
    } catch (err) {
      console.error('Forecast fetch error:', err);
      setFetchError(true);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
  }, [fetchData]);

  const requestResearch = async (id: string, name: string) => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      Alert.alert(
        'Ask Alfred',
        `Alfred will research current pricing and options for your ${name}. This may take a moment.`,
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Research',
            onPress: async () => {
              const res = await fetch(
                `${API_BASE_URL}/budgeting/forecast/system/${id}/alfred-research`,
                {
                  method: 'POST',
                  headers: { Authorization: `Bearer ${token}` },
                },
              );
              if (res.ok) {
                Alert.alert('Research Complete', 'Alfred has updated the forecast with current market data.');
                fetchData();
              } else {
                Alert.alert('Error', 'Could not complete research. Try again later.');
              }
            },
          },
        ],
      );
    } catch (err) {
      console.error('Research error:', err);
    }
  };

  return (
    <ScreenContainer
      title="Home Forecast"
      showBack={true}
      onBackPress={() => router.back()}
      refreshing={refreshing}
      onRefresh={onRefresh}
    >
      {isLoading ? (
        <View style={styles.loading}>
          <ActivityIndicator size="large" color={colors.haven.sage[500]} />
        </View>
      ) : fetchError || (!data && timeline.length === 0) ? (
        <View style={styles.noBankContainer}>
          <Ionicons name="analytics-outline" size={64} color={colors.haven.navy[300]} />
          <Text style={styles.noBankTitle}>Home Forecasts</Text>
          <Text style={styles.noBankText}>
            Connect your bank to unlock intelligent home forecasting.
            We'll analyze your spending to predict maintenance costs and system replacements.
          </Text>
          <TouchableOpacity
            style={styles.connectButton}
            onPress={() => router.push('/(tabs)/money' as any)}
          >
            <Ionicons name="link-outline" size={18} color={colors.white} />
            <Text style={styles.connectButtonText}>Connect Your Bank</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <View style={styles.content}>
          {/* Summary Banner */}
          {data && data.summary.totalSystems > 0 && (
            <View style={styles.summaryCard}>
              <View style={styles.summaryRow}>
                <View style={styles.summaryItem}>
                  <Text style={styles.summaryNumber}>{data.summary.totalSystems}</Text>
                  <Text style={styles.summaryLabel}>Systems</Text>
                </View>
                <View style={styles.summaryDivider} />
                <View style={styles.summaryItem}>
                  <Text style={[styles.summaryNumber, { color: colors.status.warning }]}>
                    {data.summary.urgentCount}
                  </Text>
                  <Text style={styles.summaryLabel}>Need Attention</Text>
                </View>
                <View style={styles.summaryDivider} />
                <View style={styles.summaryItem}>
                  <Text style={styles.summaryNumber}>
                    {formatCurrency(data.summary.totalUpcomingCost)}
                  </Text>
                  <Text style={styles.summaryLabel}>Est. Cost</Text>
                </View>
              </View>
            </View>
          )}

          {/* Tab Switcher */}
          <View style={styles.tabs}>
            <TouchableOpacity
              style={[styles.tab, activeTab === 'systems' && styles.tabActive]}
              onPress={() => setActiveTab('systems')}
            >
              <Text
                style={[styles.tabText, activeTab === 'systems' && styles.tabTextActive]}
              >
                Systems
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.tab, activeTab === 'timeline' && styles.tabActive]}
              onPress={() => setActiveTab('timeline')}
            >
              <Text
                style={[styles.tabText, activeTab === 'timeline' && styles.tabTextActive]}
              >
                Timeline
              </Text>
            </TouchableOpacity>
          </View>

          {/* Systems View */}
          {activeTab === 'systems' && (
            <>
              {data?.forecasts && data.forecasts.length > 0 ? (
                data.forecasts.map((system) => (
                  <View key={system.id} style={styles.systemCard}>
                    <View style={styles.systemHeader}>
                      <View style={styles.systemInfo}>
                        <Text style={styles.systemName}>{system.systemName}</Text>
                        <Text style={styles.systemType}>{system.systemType}</Text>
                      </View>
                      <View
                        style={[
                          styles.urgencyBadge,
                          { backgroundColor: getUrgencyColor(system.urgency) + '20' },
                        ]}
                      >
                        <View
                          style={[
                            styles.urgencyDot,
                            { backgroundColor: getUrgencyColor(system.urgency) },
                          ]}
                        />
                        <Text
                          style={[
                            styles.urgencyText,
                            { color: getUrgencyColor(system.urgency) },
                          ]}
                        >
                          {getUrgencyLabel(system.urgency)}
                        </Text>
                      </View>
                    </View>

                    <View style={styles.systemDetails}>
                      {system.installYear && (
                        <View style={styles.detailItem}>
                          <Text style={styles.detailLabel}>Installed</Text>
                          <Text style={styles.detailValue}>{system.installYear}</Text>
                        </View>
                      )}
                      {system.estimatedAge != null && (
                        <View style={styles.detailItem}>
                          <Text style={styles.detailLabel}>Age</Text>
                          <Text style={styles.detailValue}>{system.estimatedAge} yrs</Text>
                        </View>
                      )}
                      {system.typicalLifespan && (
                        <View style={styles.detailItem}>
                          <Text style={styles.detailLabel}>Lifespan</Text>
                          <Text style={styles.detailValue}>{system.typicalLifespan} yrs</Text>
                        </View>
                      )}
                      {system.estimatedReplacementCost && (
                        <View style={styles.detailItem}>
                          <Text style={styles.detailLabel}>Est. Cost</Text>
                          <Text style={styles.detailValue}>
                            {formatCurrency(system.estimatedReplacementCost)}
                          </Text>
                        </View>
                      )}
                    </View>

                    {/* Lifespan bar */}
                    {system.typicalLifespan && system.estimatedAge != null && (
                      <View style={styles.lifespanBar}>
                        <View
                          style={[
                            styles.lifespanFill,
                            {
                              width: `${Math.min(
                                (system.estimatedAge / system.typicalLifespan) * 100,
                                100,
                              )}%`,
                              backgroundColor: getUrgencyColor(system.urgency),
                            },
                          ]}
                        />
                      </View>
                    )}

                    <TouchableOpacity
                      style={styles.researchButton}
                      onPress={() => requestResearch(system.id, system.systemName)}
                    >
                      <Ionicons name="search-outline" size={16} color={colors.haven.navy[600]} />
                      <Text style={styles.researchButtonText}>Ask Alfred to Research</Text>
                    </TouchableOpacity>
                  </View>
                ))
              ) : (
                <View style={styles.emptyState}>
                  <Ionicons name="home-outline" size={48} color={colors.slate[300]} />
                  <Text style={styles.emptyTitle}>No systems tracked</Text>
                  <Text style={styles.emptySubtext}>
                    Add your home systems to forecast replacement costs and plan ahead.
                  </Text>
                </View>
              )}
            </>
          )}

          {/* Timeline View */}
          {activeTab === 'timeline' && (
            <>
              {timeline.length > 0 ? (
                timeline.map((year) => (
                  <View key={year.year} style={styles.timelineYear}>
                    <View style={styles.timelineHeader}>
                      <Text style={styles.timelineYearText}>{year.year}</Text>
                      <Text style={styles.timelineCost}>
                        {formatCurrency(year.totalCost)}
                      </Text>
                    </View>
                    {year.items.map((item, idx) => (
                      <View key={idx} style={styles.timelineItem}>
                        <View
                          style={[
                            styles.timelineDot,
                            { backgroundColor: getUrgencyColor(item.urgency) },
                          ]}
                        />
                        <Text style={styles.timelineItemName}>{item.systemName}</Text>
                        <Text style={styles.timelineItemCost}>
                          {formatCurrency(item.cost)}
                        </Text>
                      </View>
                    ))}
                  </View>
                ))
              ) : (
                <View style={styles.emptyState}>
                  <Ionicons name="calendar-outline" size={48} color={colors.slate[300]} />
                  <Text style={styles.emptyTitle}>No upcoming forecasts</Text>
                  <Text style={styles.emptySubtext}>
                    Add your home systems to see a timeline of upcoming replacement costs.
                  </Text>
                </View>
              )}
            </>
          )}
        </View>
      )}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  content: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  loading: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingTop: spacing[12],
  },

  // Summary
  summaryCard: {
    backgroundColor: colors.haven.navy[800],
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    marginBottom: spacing[4],
  },
  summaryRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  summaryItem: {
    flex: 1,
    alignItems: 'center',
  },
  summaryDivider: {
    width: 1,
    height: 40,
    backgroundColor: 'rgba(255,255,255,0.15)',
  },
  summaryNumber: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },
  summaryLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.sage[200],
    marginTop: 4,
  },

  // Tabs
  tabs: {
    flexDirection: 'row',
    backgroundColor: colors.slate[100],
    borderRadius: borderRadius.lg,
    padding: 3,
    marginBottom: spacing[4],
  },
  tab: {
    flex: 1,
    paddingVertical: spacing[2],
    alignItems: 'center',
    borderRadius: borderRadius.md,
  },
  tabActive: {
    backgroundColor: colors.white,
    ...shadows.sm,
  },
  tabText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[500],
  },
  tabTextActive: {
    color: colors.slate[900],
  },

  // System card
  systemCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginBottom: spacing[3],
    ...shadows.sm,
  },
  systemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[3],
  },
  systemInfo: {
    flex: 1,
  },
  systemName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  systemType: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  urgencyBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing[2],
    paddingVertical: 4,
    borderRadius: borderRadius.full,
    gap: 4,
  },
  urgencyDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  urgencyText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
  },
  systemDetails: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[4],
    marginBottom: spacing[3],
  },
  detailItem: {},
  detailLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
  },
  detailValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginTop: 2,
  },
  lifespanBar: {
    height: 6,
    backgroundColor: colors.slate[100],
    borderRadius: 3,
    overflow: 'hidden',
    marginBottom: spacing[3],
  },
  lifespanFill: {
    height: '100%',
    borderRadius: 3,
  },
  researchButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[2],
    borderTopWidth: 1,
    borderTopColor: colors.slate[100],
    marginTop: spacing[1],
  },
  researchButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[600],
  },

  // Timeline
  timelineYear: {
    marginBottom: spacing[4],
  },
  timelineHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
    paddingHorizontal: spacing[1],
  },
  timelineYearText: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  timelineCost: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[700],
  },
  timelineItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    marginBottom: spacing[2],
    gap: spacing[3],
    ...shadows.sm,
  },
  timelineDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  timelineItemName: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.slate[700],
  },
  timelineItemCost: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },

  // No bank connected
  noBankContainer: {
    alignItems: 'center',
    paddingVertical: spacing[12],
    paddingHorizontal: spacing[6],
  },
  noBankTitle: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[800],
    marginTop: spacing[5],
  },
  noBankText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
    textAlign: 'center',
    marginTop: spacing[3],
    lineHeight: 22,
    maxWidth: 320,
  },
  connectButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    backgroundColor: colors.haven.sage[600],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.xl,
    marginTop: spacing[6],
  },
  connectButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },

  // Empty
  emptyState: {
    alignItems: 'center',
    paddingVertical: spacing[12],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[600],
    marginTop: spacing[4],
  },
  emptySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[400],
    textAlign: 'center',
    marginTop: spacing[2],
    maxWidth: 280,
  },
});
