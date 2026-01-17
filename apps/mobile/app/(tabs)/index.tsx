import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Image,
  StatusBar,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
// Removed react-native-reanimated to fix Worklets crash
import { LinearGradient } from 'expo-linear-gradient';
import { useAuth } from '../../src/contexts/auth-context';
import { useSubscription } from '../../src/contexts/subscription-context';
import { Card, Badge, DashboardSkeleton, SectionHeader, AnimatedCard, OnboardingChecklist, OnboardingChecklistData } from '../../src/components';
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
// TYPES FOR REAL DATA
// =============================================================================

interface TodayNote {
  id: string;
  type: 'bill' | 'maintenance' | 'service' | 'activity' | 'event';
  icon: string;
  text: string;
  color: string;
  priority: number;
}

interface AlfredEmailCase {
  id: string;
  caseNumber: string;
  fromEmail: string;
  subject: string;
  status: 'RECEIVED' | 'PROCESSING' | 'AWAITING_INPUT' | 'IN_PROGRESS' | 'COMPLETED' | 'ARCHIVED';
  priority: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
  summary: string | null;
  detectedIntent: string | null;
  receivedAt: string;
}

interface TodayNotesResponse {
  notes: TodayNote[];
  isEmpty: boolean;
  counts: {
    bills: number;
    maintenance: number;
    services: number;
    activities: number;
    events: number;
  };
}

interface HealthFactorsResponse {
  score: number;
  maxScore: number;
  grade: string;
  factors: {
    helping: string[];
    needsAttention: string[];
  };
  recommendations: string[];
}

// =============================================================================
// HELPERS
// =============================================================================

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
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

// Get color based on Alfred email case status
function getAlfredStatusColor(status: string): string {
  switch (status) {
    case 'AWAITING_INPUT':
      return colors.status.warning;
    case 'COMPLETED':
      return colors.status.success;
    case 'IN_PROGRESS':
    case 'PROCESSING':
      return colors.haven.champagne[500];
    default:
      return colors.haven.navy[500];
  }
}

// Get icon based on detected intent
function getAlfredIntentIcon(intent: string | null): string {
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
}

// Get emoji and background color based on activity category
function getActivityConfig(category: string): { emoji: string; bgColor: string } {
  const configs: Record<string, { emoji: string; bgColor: string }> = {
    PROPERTY: { emoji: '🏠', bgColor: '#E0E7FF' },      // Indigo tint
    BILLING: { emoji: '💰', bgColor: '#D1FAE5' },       // Green tint
    FAMILY: { emoji: '👨‍👩‍👧‍👦', bgColor: '#FCE7F3' },       // Pink tint
    MAINTENANCE: { emoji: '🔧', bgColor: '#FEF3C7' },   // Amber tint
    SERVICE: { emoji: '👷', bgColor: '#DBEAFE' },       // Blue tint
    COMMUNICATION: { emoji: '💬', bgColor: '#F3E8FF' }, // Purple tint
    SYSTEM: { emoji: '🤖', bgColor: '#E5E7EB' },        // Gray tint
  };
  return configs[category] || { emoji: '📌', bgColor: '#F3F4F6' };
}

// =============================================================================
// COMPONENT
// =============================================================================

export default function DashboardScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { user, householdInfo } = useAuth();
  const { tierDetails } = useSubscription();
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [data, setData] = useState<DashboardResponse | null>(null);
  const [familyData, setFamilyData] = useState<FamilyData | null>(null);
  const [onboardingData, setOnboardingData] = useState<OnboardingChecklistData | null>(null);
  const [todayNotes, setTodayNotes] = useState<TodayNotesResponse | null>(null);
  const [healthFactors, setHealthFactors] = useState<HealthFactorsResponse | null>(null);
  const [alfredCases, setAlfredCases] = useState<AlfredEmailCase[]>([]);
  const [alfredNeedsInput, setAlfredNeedsInput] = useState(0);
  const [showOnboardingChecklist, setShowOnboardingChecklist] = useState(true);
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

      // Fetch dashboard, family, onboarding, today's notes, health factors, and Alfred cases in parallel
      const [dashboardRes, familyRes, onboardingRes, todayRes, healthRes, alfredRes] = await Promise.all([
        fetch(`${API_BASE_URL}/dashboard/household/${householdInfo.id}`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/dashboard/household/${householdInfo.id}/family`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/dashboard/household/${householdInfo.id}/onboarding`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/dashboard/household/${householdInfo.id}/today`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/dashboard/household/${householdInfo.id}/health`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/alfred/cases?limit=5`, {
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

      if (onboardingRes.ok) {
        const onboarding = await onboardingRes.json();
        setOnboardingData(onboarding);
      }

      if (todayRes.ok) {
        const today = await todayRes.json();
        setTodayNotes(today);
      }

      if (healthRes.ok) {
        const health = await healthRes.json();
        setHealthFactors(health);
      }

      if (alfredRes.ok) {
        const cases = await alfredRes.json();
        setAlfredCases(Array.isArray(cases) ? cases : []);
        // Count cases needing user input
        const needsInput = (Array.isArray(cases) ? cases : []).filter(
          (c: AlfredEmailCase) => c.status === 'AWAITING_INPUT'
        ).length;
        setAlfredNeedsInput(needsInput);
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
      <View style={styles.container}>
        <View style={{ paddingTop: insets.top }}>
          <DashboardSkeleton />
        </View>
      </View>
    );
  }

  if (error || !data) {
    return (
      <View style={styles.container}>
        <View style={[styles.errorContainer, { paddingTop: insets.top }]}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Dashboard</Text>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchDashboard}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  const firstName = user?.firstName || 'there';
  const today = new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={colors.haven.navy[950]} />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={<RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />}
        showsVerticalScrollIndicator={false}
      >
        {/* Hero Header */}
        <View>
          <LinearGradient
            colors={[colors.haven.navy[950], colors.haven.navy[900]]}
            style={[styles.heroGradient, { paddingTop: insets.top + spacing[2] }]}
          >
            {/* Date Row */}
            <View style={styles.heroTop}>
              <Text style={styles.heroDate}>{today}</Text>
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
                  <Text style={styles.heroStatValue}>
                    {data.homeHealth}%
                  </Text>
                  <View style={[styles.healthBadge, { backgroundColor: getHealthColor(data.homeHealth) }]}>
                    <Text style={styles.healthBadgeText}>{getHealthLabel(data.homeHealth)}</Text>
                  </View>
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
        </View>

        {/* Health Score Details (expandable) */}
        {showHealthDetails && healthFactors && (
          <AnimatedCard style={styles.healthDetailsCard} delay={0}>
            <Text style={styles.healthDetailsTitle}>What affects your score</Text>
            <View style={styles.healthFactors}>
              {healthFactors.factors?.helping && healthFactors.factors.helping.length > 0 && (
                <View style={styles.healthFactorSection}>
                  <View style={styles.healthFactorHeader}>
                    <Ionicons name="trending-up" size={16} color={colors.status.success} />
                    <Text style={styles.healthFactorLabel}>Helping</Text>
                  </View>
                  {healthFactors.factors.helping.map((item, i) => (
                    <Text key={i} style={styles.healthFactorItem}>• {item}</Text>
                  ))}
                </View>
              )}
              {healthFactors.factors?.needsAttention && healthFactors.factors.needsAttention.length > 0 && (
                <View style={styles.healthFactorSection}>
                  <View style={styles.healthFactorHeader}>
                    <Ionicons name="trending-down" size={16} color={colors.status.warning} />
                    <Text style={styles.healthFactorLabel}>Needs Attention</Text>
                  </View>
                  {healthFactors.factors.needsAttention.map((item, i) => (
                    <Text key={i} style={styles.healthFactorItem}>• {item}</Text>
                  ))}
                </View>
              )}
              {(!healthFactors.factors?.helping || healthFactors.factors.helping.length === 0) &&
               (!healthFactors.factors?.needsAttention || healthFactors.factors.needsAttention.length === 0) && (
                <Text style={styles.healthFactorItem}>No detailed factors available yet. Complete your home setup to see more insights.</Text>
              )}
            </View>
            {healthFactors.recommendations && healthFactors.recommendations.length > 0 && (
              <View style={styles.recommendationsSection}>
                <Text style={styles.healthFactorLabel}>Top Recommendations</Text>
                {healthFactors.recommendations.slice(0, 3).map((rec, i) => (
                  <Text key={i} style={styles.healthFactorItem}>• {rec}</Text>
                ))}
              </View>
            )}
          </AnimatedCard>
        )}

        {/* Onboarding Checklist - shown for new users who haven't completed all items */}
        {showOnboardingChecklist && onboardingData && (
          <OnboardingChecklist
            data={onboardingData}
            onDismiss={() => setShowOnboardingChecklist(false)}
          />
        )}

        {/* Today's Notes */}
        <AnimatedCard style={styles.notesCard} delay={100}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Today's Notes</Text>
            {todayNotes && todayNotes.notes.length > 0 && (
              <Badge label={`${todayNotes.notes.length}`} variant="info" />
            )}
          </View>
          {todayNotes && todayNotes.notes.length > 0 ? (
            todayNotes.notes.map((note) => (
              <View key={note.id} style={styles.noteRow}>
                <View style={[styles.noteIcon, { backgroundColor: note.color + '20' }]}>
                  <Ionicons name={note.icon as keyof typeof Ionicons.glyphMap} size={16} color={note.color} />
                </View>
                <Text style={styles.noteText}>{note.text}</Text>
              </View>
            ))
          ) : (
            <View style={styles.emptyNotesContainer}>
              <Ionicons name="checkmark-circle-outline" size={32} color={colors.status.success} />
              <Text style={styles.emptyNotesTitle}>All caught up!</Text>
              <Text style={styles.emptyNotesSubtitle}>
                No bills due, maintenance tasks, or events for today
              </Text>
            </View>
          )}
        </AnimatedCard>

        {/* Family Status - Always show with add option */}
        <AnimatedCard style={styles.familyCard} delay={150}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Family</Text>
            <TouchableOpacity onPress={() => router.push('/(tabs)/family')}>
              <Text style={styles.seeAllLink}>Manage</Text>
            </TouchableOpacity>
          </View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.familyScroll}>
            {familyData?.members.map((member) => (
              <TouchableOpacity
                key={member.id}
                style={styles.familyMember}
                onPress={() => router.push(`/(tabs)/family/member/${member.id}` as any)}
                activeOpacity={0.7}
              >
                <View style={styles.familyAvatar}>
                  <Ionicons name={getAvatarType(member)} size={24} color={colors.haven.navy[600]} />
                </View>
                <Text style={styles.familyName} numberOfLines={1}>{member.firstName}</Text>
                <Text style={styles.familyRole} numberOfLines={1}>
                  {member.type === 'CHILD' ? 'Child' : member.type === 'STAFF' ? 'Staff' : 'Adult'}
                </Text>
              </TouchableOpacity>
            ))}
            {familyData?.pets.map((pet) => (
              <TouchableOpacity
                key={pet.id}
                style={styles.familyMember}
                onPress={() => router.push(`/(tabs)/family/pet/${pet.id}` as any)}
                activeOpacity={0.7}
              >
                <View style={[styles.familyAvatar, { backgroundColor: colors.haven.champagne[100] }]}>
                  <Ionicons name="paw-outline" size={24} color={colors.haven.champagne[600]} />
                </View>
                <Text style={styles.familyName} numberOfLines={1}>{pet.name}</Text>
                <Text style={styles.familyRole} numberOfLines={1}>{pet.breed || pet.species}</Text>
              </TouchableOpacity>
            ))}
            {/* Add Member Button */}
            <TouchableOpacity
              style={styles.familyMember}
              onPress={() => router.push('/(tabs)/family')}
              activeOpacity={0.7}
            >
              <View style={styles.addMemberAvatar}>
                <Ionicons name="add" size={24} color={colors.haven.champagne[500]} />
              </View>
              <Text style={styles.familyName} numberOfLines={1}>Add</Text>
              <Text style={styles.familyRole} numberOfLines={1}>Member</Text>
            </TouchableOpacity>
          </ScrollView>
        </AnimatedCard>

        {/* Alfred Email Activity */}
        <AnimatedCard style={styles.alfredCard} delay={175}>
          <View style={styles.cardHeader}>
            <View style={styles.alfredHeaderLeft}>
              <Text style={styles.cardTitle}>Alfred Activity</Text>
              {alfredNeedsInput > 0 && (
                <Badge label={`${alfredNeedsInput} needs input`} variant="warning" size="sm" />
              )}
            </View>
            <TouchableOpacity onPress={() => router.push('/(tabs)/settings/alfred-cases' as any)}>
              <Text style={styles.seeAllLink}>View All</Text>
            </TouchableOpacity>
          </View>
          {alfredCases.length > 0 ? (
            alfredCases.slice(0, 3).map((emailCase, index) => (
              <TouchableOpacity
                key={emailCase.id}
                style={[styles.alfredCaseRow, index < Math.min(alfredCases.length, 3) - 1 && styles.alfredCaseBorder]}
                onPress={() => router.push(`/(tabs)/settings/alfred-case/${emailCase.id}` as any)}
              >
                <View style={[styles.alfredCaseIcon, { backgroundColor: getAlfredStatusColor(emailCase.status) + '15' }]}>
                  <Ionicons
                    name={getAlfredIntentIcon(emailCase.detectedIntent) as any}
                    size={20}
                    color={getAlfredStatusColor(emailCase.status)}
                  />
                </View>
                <View style={styles.alfredCaseContent}>
                  <Text style={styles.alfredCaseSubject} numberOfLines={1}>{emailCase.subject}</Text>
                  <Text style={styles.alfredCaseFrom} numberOfLines={1}>{emailCase.fromEmail}</Text>
                </View>
                <View style={styles.alfredCaseMeta}>
                  {emailCase.status === 'AWAITING_INPUT' ? (
                    <Badge label="Action" variant="warning" size="sm" />
                  ) : (
                    <Text style={styles.alfredCaseTime}>{formatRelativeTime(emailCase.receivedAt)}</Text>
                  )}
                </View>
              </TouchableOpacity>
            ))
          ) : (
            <View style={styles.alfredEmptyContainer}>
              <Ionicons name="mail-outline" size={32} color={colors.gray[300]} />
              <Text style={styles.alfredEmptyTitle}>No emails yet</Text>
              <Text style={styles.alfredEmptyText}>
                CC Alfred on your emails to get started
              </Text>
              <TouchableOpacity
                style={styles.alfredSetupButton}
                onPress={() => router.push('/(tabs)/settings/alfred-email' as any)}
              >
                <Text style={styles.alfredSetupButtonText}>Set Up Alfred Email</Text>
              </TouchableOpacity>
            </View>
          )}
        </AnimatedCard>

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
          <AnimatedCard style={styles.managerCard} delay={200} onPress={() => router.push('/(tabs)/manager')}>
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
            <TouchableOpacity style={styles.quickAction} onPress={() => router.push('/(tabs)/manager')}>
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
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Recent Activity</Text>
            <TouchableOpacity onPress={() => router.push('/(tabs)/activity' as any)}>
              <Text style={styles.seeAllLink}>See All</Text>
            </TouchableOpacity>
          </View>
          <AnimatedCard style={styles.activityCard} delay={300}>
            {data.recentActivity.length === 0 ? (
              <View style={styles.activityEmpty}>
                <Ionicons name="newspaper-outline" size={32} color={colors.gray[300]} />
                <Text style={styles.activityEmptyText}>No recent activity</Text>
              </View>
            ) : (
              data.recentActivity.slice(0, 5).map((activity, index) => {
                const config = getActivityConfig(activity.category);
                return (
                  <View
                    key={activity.id}
                    style={[styles.activityRow, index < Math.min(data.recentActivity.length, 5) - 1 && styles.activityBorder]}
                  >
                    <View style={[styles.activityEmoji, { backgroundColor: config.bgColor }]}>
                      <Text style={styles.activityEmojiText}>{config.emoji}</Text>
                    </View>
                    <View style={styles.activityContent}>
                      <Text style={styles.activityTitle} numberOfLines={1}>{activity.title}</Text>
                      {activity.description && (
                        <Text style={styles.activityDescription} numberOfLines={1}>{activity.description}</Text>
                      )}
                      <View style={styles.activityMeta}>
                        {activity.actorName && (
                          <Text style={styles.activityActor}>{activity.actorName}</Text>
                        )}
                        <Text style={styles.activityTime}>{formatRelativeTime(activity.createdAt)}</Text>
                      </View>
                    </View>
                  </View>
                );
              })
            )}
          </AnimatedCard>
        </View>
      </ScrollView>
    </View>
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
  heroGreeting: {
    fontSize: 28,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    marginBottom: spacing[1],
    letterSpacing: -0.5,  // Tighter for large display text
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
  healthBadge: {
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
    flexShrink: 0,  // Prevent shrinking in flex container
  },
  healthBadgeText: {
    fontSize: 11,
    fontWeight: typography.fontWeights.semibold,
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
  emptyNotesContainer: {
    alignItems: 'center',
    paddingVertical: spacing[4],
    gap: spacing[2],
  },
  emptyNotesTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  emptyNotesSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
  },
  recommendationsSection: {
    marginTop: spacing[4],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
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
  addMemberAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.haven.champagne[50],
    borderWidth: 2,
    borderColor: colors.haven.champagne[300],
    borderStyle: 'dashed',
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
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    gap: spacing[3],
  },
  activityBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  activityEmoji: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  activityEmojiText: {
    fontSize: 18,
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
  activityMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: 4,
  },
  activityActor: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  activityTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  activityEmpty: {
    padding: spacing[8],
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
  },
  activityEmptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },

  // Alfred Activity Card
  alfredCard: {
    marginHorizontal: spacing[4],
    marginTop: spacing[4],
    padding: spacing[4],
  },
  alfredHeaderLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  alfredCaseRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    gap: spacing[3],
  },
  alfredCaseBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  alfredCaseIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  alfredCaseContent: {
    flex: 1,
  },
  alfredCaseSubject: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  alfredCaseFrom: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  alfredCaseMeta: {
    alignItems: 'flex-end',
  },
  alfredCaseTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  alfredEmptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing[6],
    gap: spacing[2],
  },
  alfredEmptyTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  alfredEmptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
  },
  alfredSetupButton: {
    marginTop: spacing[3],
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
  },
  alfredSetupButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
});
