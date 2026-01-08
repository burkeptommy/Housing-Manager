import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Image,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import Animated, { FadeInUp, FadeInDown } from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuth } from '../../src/contexts/auth-context';
import { Card, Badge, DashboardSkeleton, SectionHeader, AnimatedCard } from '../../src/components';
import { colors, typography, spacing, borderRadius, shadows } from '../../src/lib/theme';
import { API_BASE_URL } from '../../src/lib/api';
import { getIdToken } from '../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface DashboardResponse {
  household: {
    id: string;
    name: string;
    propertyAddress: string | null;
  };
  manager: {
    id: string;
    name: string;
    email: string;
    phone: string | null;
  } | null;
  homeHealth: number;
  billing: {
    monthlyFunding: number;
    amountPaid: number;
    billsPaidCount: number;
    bufferRemaining: number;
  };
  nextService: {
    title: string;
    vendorName: string | null;
    date: string;
  } | null;
  pendingApprovals: number;
  recentActivity: Array<{
    id: string;
    title: string;
    description: string | null;
    actorName: string | null;
    category: string;
    createdAt: string;
  }>;
  upcoming: Array<{
    id: string;
    title: string;
    type: string;
    date: string;
  }>;
}

interface FamilyMember {
  id: string;
  firstName: string;
  lastName: string | null;
  type: 'ADULT' | 'CHILD' | 'STAFF';
  relationship: string | null;
  avatarUrl: string | null;
}

interface Pet {
  id: string;
  name: string;
  species: string;
  breed: string | null;
}

interface FamilyData {
  members: FamilyMember[];
  pets: Pet[];
  summary: {
    adults: number;
    children: number;
    pets: number;
    staff: number;
  };
}

// =============================================================================
// MOCK DATA (matches web)
// =============================================================================

const mockWeather = { temp: 68, condition: 'sunny' as const };

const mockTodayNotes = [
  { id: 'trash', icon: 'trash-outline' as const, text: 'Trash day tomorrow - bins out?', color: colors.status.warning },
  { id: 'package', icon: 'cube-outline' as const, text: 'Amazon delivery expected 2-5pm', color: colors.haven.navy[500] },
  { id: 'soccer', icon: 'calendar-outline' as const, text: "Emma's soccer practice 4pm", color: colors.haven.champagne[500] },
];

const mockHealthFactors = {
  helping: ['HVAC serviced recently', 'All bills current', 'No overdue maintenance'],
  hurting: ['Gutter cleaning due soon'],
};

// =============================================================================
// HELPERS
// =============================================================================

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

function getWeatherIcon(condition: string): keyof typeof Ionicons.glyphMap {
  switch (condition) {
    case 'sunny': return 'sunny-outline';
    case 'cloudy': return 'cloud-outline';
    case 'rainy': return 'rainy-outline';
    default: return 'partly-sunny-outline';
  }
}

function getHealthColor(score: number) {
  if (score >= 90) return colors.status.success;
  if (score >= 70) return colors.status.warning;
  return colors.status.error;
}

function getHealthLabel(score: number) {
  if (score >= 90) return 'Excellent';
  if (score >= 70) return 'Good';
  if (score >= 50) return 'Fair';
  return 'Needs Attention';
}

function getAvatarType(member: FamilyMember): keyof typeof Ionicons.glyphMap {
  if (member.type === 'CHILD') {
    return member.relationship?.toLowerCase().includes('daughter') ? 'person-outline' : 'person-outline';
  }
  return 'person-outline';
}

function formatCurrency(amount: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

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
  return `${diffDays}d ago`;
}

// =============================================================================
// COMPONENT
// =============================================================================

export default function DashboardScreen() {
  const router = useRouter();
  const { user, householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [data, setData] = useState<DashboardResponse | null>(null);
  const [familyData, setFamilyData] = useState<FamilyData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [showHealthDetails, setShowHealthDetails] = useState(false);

  const fetchDashboard = useCallback(async () => {
    if (!householdInfo?.id) {
      setIsLoading(false);
      setError('No household found. Please complete onboarding.');
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        setIsLoading(false);
        return;
      }

      // Fetch dashboard and family data in parallel
      const [dashboardRes, familyRes] = await Promise.all([
        fetch(`${API_BASE_URL}/dashboard/household/${householdInfo.id}`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/dashboard/household/${householdInfo.id}/family`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (!dashboardRes.ok) {
        throw new Error(`Failed to fetch dashboard: ${dashboardRes.status}`);
      }

      const dashboardData = await dashboardRes.json();
      setData(dashboardData);

      if (familyRes.ok) {
        const family = await familyRes.json();
        setFamilyData(family);
      }

      setError(null);
    } catch (err) {
      console.error('Dashboard fetch error:', err);
      setError('Failed to load dashboard. Please try again.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchDashboard();
  }, [fetchDashboard]);

  const onRefresh = () => {
    setIsRefreshing(true);
    fetchDashboard();
  };

  if (isLoading) {
    return (
      <SafeAreaView style={styles.container} edges={['top']}>
        <DashboardSkeleton />
      </SafeAreaView>
    );
  }

  if (error || !data) {
    return (
      <SafeAreaView style={styles.container} edges={['top']}>
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Dashboard</Text>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchDashboard}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const firstName = user?.firstName || 'there';
  const today = new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={<RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />}
        showsVerticalScrollIndicator={false}
      >
        {/* Hero Header */}
        <Animated.View entering={FadeInDown.duration(400)}>
          <LinearGradient
            colors={[colors.haven.navy[900], colors.haven.navy[800]]}
            style={styles.heroGradient}
          >
            {/* Date and Weather Row */}
            <View style={styles.heroTop}>
              <Text style={styles.heroDate}>{today}</Text>
              <View style={styles.weatherBadge}>
                <Ionicons name={getWeatherIcon(mockWeather.condition)} size={20} color={colors.white} />
                <Text style={styles.weatherTemp}>{mockWeather.temp}°</Text>
              </View>
            </View>

            {/* Greeting */}
            <Text style={styles.heroGreeting}>{getGreeting()}, {firstName}</Text>
            <Text style={styles.heroSubtext}>Your home is in great shape.</Text>

            {/* Quick Stats */}
            <View style={styles.heroStats}>
              {/* Home Health */}
              <TouchableOpacity
                style={[styles.heroStat, styles.heroStatHealth]}
                onPress={() => setShowHealthDetails(!showHealthDetails)}
              >
                <Text style={styles.heroStatLabel}>Home Health</Text>
                <View style={styles.heroStatRow}>
                  <Text style={[styles.heroStatValue, { color: getHealthColor(data.homeHealth) }]}>
                    {data.homeHealth}%
                  </Text>
                  <Badge
                    label={getHealthLabel(data.homeHealth)}
                    variant={data.homeHealth >= 90 ? 'success' : data.homeHealth >= 70 ? 'warning' : 'error'}
                  />
                </View>
              </TouchableOpacity>

              {/* Bills Paid */}
              <View style={styles.heroStat}>
                <Text style={styles.heroStatLabel}>Bills Paid</Text>
                <Text style={styles.heroStatValue}>{data.billing.billsPaidCount}</Text>
              </View>

              {/* Next Service */}
              <View style={styles.heroStat}>
                <Text style={styles.heroStatLabel}>Next Service</Text>
                <Text style={styles.heroStatValue}>
                  {data.nextService ? new Date(data.nextService.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) : '—'}
                </Text>
              </View>
            </View>
          </LinearGradient>
        </Animated.View>

        {/* Health Score Details (expandable) */}
        {showHealthDetails && (
          <AnimatedCard style={styles.healthDetailsCard} delay={0}>
            <Text style={styles.healthDetailsTitle}>What affects your score</Text>
            <View style={styles.healthFactors}>
              <View style={styles.healthFactorSection}>
                <View style={styles.healthFactorHeader}>
                  <Ionicons name="trending-up" size={16} color={colors.status.success} />
                  <Text style={styles.healthFactorLabel}>Helping</Text>
                </View>
                {mockHealthFactors.helping.map((item, i) => (
                  <Text key={i} style={styles.healthFactorItem}>• {item}</Text>
                ))}
              </View>
              <View style={styles.healthFactorSection}>
                <View style={styles.healthFactorHeader}>
                  <Ionicons name="trending-down" size={16} color={colors.status.warning} />
                  <Text style={styles.healthFactorLabel}>Needs Attention</Text>
                </View>
                {mockHealthFactors.hurting.map((item, i) => (
                  <Text key={i} style={styles.healthFactorItem}>• {item}</Text>
                ))}
              </View>
            </View>
          </AnimatedCard>
        )}

        {/* Today's Notes */}
        <AnimatedCard style={styles.notesCard} delay={100}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Today's Notes</Text>
            <Badge label={`${mockTodayNotes.length}`} variant="info" />
          </View>
          {mockTodayNotes.map((note) => (
            <View key={note.id} style={styles.noteRow}>
              <View style={[styles.noteIcon, { backgroundColor: note.color + '20' }]}>
                <Ionicons name={note.icon} size={16} color={note.color} />
              </View>
              <Text style={styles.noteText}>{note.text}</Text>
            </View>
          ))}
        </AnimatedCard>

        {/* Family Status */}
        {familyData && (familyData.members.length > 0 || familyData.pets.length > 0) && (
          <AnimatedCard style={styles.familyCard} delay={150}>
            <View style={styles.cardHeader}>
              <Text style={styles.cardTitle}>Family</Text>
              <TouchableOpacity onPress={() => router.push('/(tabs)/family')}>
                <Text style={styles.seeAllLink}>See all</Text>
              </TouchableOpacity>
            </View>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.familyScroll}>
              {familyData.members.map((member) => (
                <View key={member.id} style={styles.familyMember}>
                  <View style={styles.familyAvatar}>
                    <Ionicons name={getAvatarType(member)} size={24} color={colors.haven.navy[600]} />
                  </View>
                  <Text style={styles.familyName} numberOfLines={1}>{member.firstName}</Text>
                  <Text style={styles.familyRole} numberOfLines={1}>
                    {member.type === 'CHILD' ? 'Child' : member.type === 'STAFF' ? 'Staff' : 'Adult'}
                  </Text>
                </View>
              ))}
              {familyData.pets.map((pet) => (
                <View key={pet.id} style={styles.familyMember}>
                  <View style={[styles.familyAvatar, { backgroundColor: colors.haven.champagne[100] }]}>
                    <Ionicons name="paw-outline" size={24} color={colors.haven.champagne[600]} />
                  </View>
                  <Text style={styles.familyName} numberOfLines={1}>{pet.name}</Text>
                  <Text style={styles.familyRole} numberOfLines={1}>{pet.breed || pet.species}</Text>
                </View>
              ))}
            </ScrollView>
          </AnimatedCard>
        )}

        {/* Pending Approvals Alert */}
        {data.pendingApprovals > 0 && (
          <TouchableOpacity
            style={styles.alertCard}
            onPress={() => router.push('/(tabs)/approvals')}
          >
            <View style={styles.alertIcon}>
              <Ionicons name="checkmark-circle" size={24} color={colors.status.warning} />
            </View>
            <View style={styles.alertContent}>
              <Text style={styles.alertTitle}>
                {data.pendingApprovals} Pending Approval{data.pendingApprovals > 1 ? 's' : ''}
              </Text>
              <Text style={styles.alertSubtitle}>Tap to review and approve</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
          </TouchableOpacity>
        )}

        {/* Manager Card */}
        {data.manager && (
          <AnimatedCard style={styles.managerCard} delay={200} onPress={() => router.push('/(tabs)/sarah')}>
            <View style={styles.managerHeader}>
              <View style={styles.managerAvatar}>
                <Text style={styles.managerInitials}>
                  {data.manager.name.split(' ').map(n => n[0]).join('')}
                </Text>
                <View style={styles.onlineIndicator} />
              </View>
              <View style={styles.managerInfo}>
                <Text style={styles.managerName}>{data.manager.name}</Text>
                <Text style={styles.managerLabel}>Your Home Manager</Text>
              </View>
              <View style={styles.managerActions}>
                <TouchableOpacity style={styles.managerActionBtn}>
                  <Ionicons name="chatbubble" size={20} color={colors.haven.champagne[500]} />
                </TouchableOpacity>
              </View>
            </View>
          </AnimatedCard>
        )}

        {/* Quick Actions Grid */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Quick Actions</Text>
          <View style={styles.quickActions}>
            <TouchableOpacity style={styles.quickAction} onPress={() => router.push('/(tabs)/sarah')}>
              <View style={[styles.quickIcon, { backgroundColor: colors.haven.champagne[100] }]}>
                <Ionicons name="chatbubble" size={22} color={colors.haven.champagne[600]} />
              </View>
              <Text style={styles.quickLabel}>Message</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.quickAction} onPress={() => router.push('/(tabs)/approvals')}>
              <View style={[styles.quickIcon, { backgroundColor: colors.haven.navy[100] }]}>
                <Ionicons name="checkmark-circle" size={22} color={colors.haven.navy[600]} />
              </View>
              <Text style={styles.quickLabel}>Approvals</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.quickAction} onPress={() => router.push('/(tabs)/maintenance')}>
              <View style={[styles.quickIcon, { backgroundColor: colors.status.warningLight }]}>
                <Ionicons name="construct" size={22} color={colors.status.warning} />
              </View>
              <Text style={styles.quickLabel}>Maintenance</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.quickAction} onPress={() => router.push('/(tabs)/vault')}>
              <View style={[styles.quickIcon, { backgroundColor: colors.gray[100] }]}>
                <Ionicons name="folder" size={22} color={colors.gray[600]} />
              </View>
              <Text style={styles.quickLabel}>Documents</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Recent Activity */}
        {data.recentActivity.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Recent Activity</Text>
            <AnimatedCard style={styles.activityCard} delay={300}>
              {data.recentActivity.slice(0, 5).map((activity, index) => (
                <View
                  key={activity.id}
                  style={[styles.activityRow, index < Math.min(data.recentActivity.length, 5) - 1 && styles.activityBorder]}
                >
                  <View style={styles.activityIcon}>
                    <Ionicons name="ellipse" size={8} color={colors.haven.champagne[500]} />
                  </View>
                  <View style={styles.activityContent}>
                    <Text style={styles.activityTitle} numberOfLines={1}>{activity.title}</Text>
                    {activity.actorName && (
                      <Text style={styles.activityActor}>{activity.actorName}</Text>
                    )}
                  </View>
                  <Text style={styles.activityTime}>{formatRelativeTime(activity.createdAt)}</Text>
                </View>
              ))}
            </AnimatedCard>
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  scrollContent: {
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

  // Hero Section
  heroGradient: {
    paddingHorizontal: spacing[4],
    paddingTop: spacing[2],
    paddingBottom: spacing[5],
    borderBottomLeftRadius: borderRadius['2xl'],
    borderBottomRightRadius: borderRadius['2xl'],
  },
  heroTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  heroDate: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[200],
  },
  weatherBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    backgroundColor: 'rgba(255,255,255,0.15)',
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
  },
  weatherTemp: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  heroGreeting: {
    fontSize: 28,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    marginBottom: spacing[1],
  },
  heroSubtext: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.champagne[200],
    marginBottom: spacing[4],
  },
  heroStats: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  heroStat: {
    flex: 1,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: borderRadius.xl,
    padding: spacing[3],
  },
  heroStatHealth: {
    flex: 1.5,
  },
  heroStatLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.champagne[200],
    marginBottom: spacing[1],
  },
  heroStatRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  heroStatValue: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },

  // Health Details
  healthDetailsCard: {
    marginHorizontal: spacing[4],
    marginTop: spacing[4],
    padding: spacing[4],
  },
  healthDetailsTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[3],
  },
  healthFactors: {
    gap: spacing[3],
  },
  healthFactorSection: {},
  healthFactorHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[1],
  },
  healthFactorLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  healthFactorItem: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    paddingLeft: spacing[5],
    paddingVertical: 2,
  },

  // Notes Card
  notesCard: {
    marginHorizontal: spacing[4],
    marginTop: spacing[4],
    padding: spacing[4],
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  cardTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  noteRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[2],
  },
  noteIcon: {
    width: 32,
    height: 32,
    borderRadius: borderRadius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  noteText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
  },

  // Family Card
  familyCard: {
    marginHorizontal: spacing[4],
    marginTop: spacing[4],
    padding: spacing[4],
  },
  seeAllLink: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[500],
    fontWeight: typography.fontWeights.medium,
  },
  familyScroll: {
    marginHorizontal: -spacing[2],
  },
  familyMember: {
    alignItems: 'center',
    paddingHorizontal: spacing[3],
    width: 80,
  },
  familyAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.haven.navy[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  familyName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    textAlign: 'center',
  },
  familyRole: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    textAlign: 'center',
  },

  // Alert Card
  alertCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.status.warningLight,
    marginHorizontal: spacing[4],
    marginTop: spacing[4],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.status.warning,
  },
  alertIcon: {
    marginRight: spacing[3],
  },
  alertContent: {
    flex: 1,
  },
  alertTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  alertSubtitle: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },

  // Manager Card
  managerCard: {
    marginHorizontal: spacing[4],
    marginTop: spacing[4],
    padding: spacing[4],
  },
  managerHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  managerAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  managerInitials: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  onlineIndicator: {
    position: 'absolute',
    bottom: 2,
    right: 2,
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: colors.status.success,
    borderWidth: 2,
    borderColor: colors.white,
  },
  managerInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  managerName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  managerLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
  },
  managerActions: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  managerActionBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },

  // Sections
  section: {
    marginTop: spacing[6],
    paddingHorizontal: spacing[4],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[3],
  },

  // Quick Actions
  quickActions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[3],
  },
  quickAction: {
    width: '47%',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.xl,
    alignItems: 'center',
    ...shadows.sm,
  },
  quickIcon: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.xl,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  quickLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },

  // Activity
  activityCard: {
    padding: spacing[3],
  },
  activityRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
  },
  activityBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  activityIcon: {
    width: 24,
    alignItems: 'center',
    marginRight: spacing[3],
  },
  activityContent: {
    flex: 1,
  },
  activityTitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
  },
  activityActor: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  activityTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
});
