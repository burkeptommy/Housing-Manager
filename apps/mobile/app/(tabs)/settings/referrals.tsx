import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Share,
  Alert,
  ActivityIndicator,
  Clipboard,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';
import { Card } from '../../../src/components';

interface ReferralStats {
  totalReferrals: number;
  pendingReferrals: number;
  signedUpReferrals: number;
  convertedReferrals: number;
  totalEarnings: number;
  pendingEarnings: number;
  referralCode: string;
  shareUrl: string;
}

interface Referral {
  id: string;
  referralCode: string;
  refereeEmail?: string;
  status: 'PENDING' | 'SIGNED_UP' | 'CONVERTED' | 'EXPIRED';
  rewardEarned: boolean;
  rewardAmount?: number;
  signedUpAt?: string;
  convertedAt?: string;
  expiresAt: string;
  createdAt: string;
  referee?: {
    firstName: string;
    lastName: string;
  };
}

export default function ReferralsScreen() {
  const [stats, setStats] = useState<ReferralStats | null>(null);
  const [referrals, setReferrals] = useState<Referral[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const [statsRes, referralsRes] = await Promise.all([
        fetch(`${API_BASE_URL}/referrals/stats`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/referrals`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (statsRes.ok) {
        const statsData = await statsRes.json();
        setStats(statsData);
      }

      if (referralsRes.ok) {
        const referralsData = await referralsRes.json();
        setReferrals(referralsData);
      }
    } catch (error) {
      console.error('Error fetching referral data:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleShare = async () => {
    if (!stats) return;

    try {
      await Share.share({
        message: `Join me on Haven - the smart home management app! Use my referral code ${stats.referralCode} or sign up at ${stats.shareUrl}`,
        url: stats.shareUrl,
        title: 'Invite to Haven',
      });
    } catch (error) {
      console.error('Error sharing:', error);
    }
  };

  const handleCopyCode = () => {
    if (!stats) return;
    Clipboard.setString(stats.referralCode);
    Alert.alert('Copied!', 'Referral code copied to clipboard');
  };

  const handleCopyLink = () => {
    if (!stats) return;
    Clipboard.setString(stats.shareUrl);
    Alert.alert('Copied!', 'Referral link copied to clipboard');
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'CONVERTED':
        return colors.status.success;
      case 'SIGNED_UP':
        return colors.status.info;
      case 'EXPIRED':
        return colors.text.tertiary;
      default:
        return colors.haven.champagne[500];
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'CONVERTED':
        return 'Subscribed';
      case 'SIGNED_UP':
        return 'Signed Up';
      case 'EXPIRED':
        return 'Expired';
      default:
        return 'Pending';
    }
  };

  if (isLoading) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Refer a Friend', headerBackTitle: 'Settings' }} />
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.navy[900]} />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: 'Refer a Friend', headerBackTitle: 'Settings' }} />

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
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
        {/* Hero Card */}
        <Card style={styles.heroCard}>
          <View style={styles.heroIcon}>
            <Ionicons name="gift" size={40} color={colors.haven.champagne[500]} />
          </View>
          <Text style={styles.heroTitle}>Share Haven & Earn $50</Text>
          <Text style={styles.heroSubtitle}>
            Invite friends to Haven. When they subscribe, you both earn $50!
          </Text>
        </Card>

        {/* Stats Cards */}
        {stats && (
          <View style={styles.statsRow}>
            <Card style={styles.statCard}>
              <Text style={styles.statValue}>{stats.totalReferrals}</Text>
              <Text style={styles.statLabel}>Referrals</Text>
            </Card>
            <Card style={styles.statCard}>
              <Text style={styles.statValue}>{stats.convertedReferrals}</Text>
              <Text style={styles.statLabel}>Converted</Text>
            </Card>
            <Card style={styles.statCard}>
              <Text style={[styles.statValue, { color: colors.status.success }]}>
                ${stats.totalEarnings}
              </Text>
              <Text style={styles.statLabel}>Earned</Text>
            </Card>
          </View>
        )}

        {/* Referral Code Card */}
        {stats && (
          <Card style={styles.codeCard}>
            <Text style={styles.codeLabel}>Your Referral Code</Text>
            <View style={styles.codeRow}>
              <Text style={styles.codeValue}>{stats.referralCode}</Text>
              <TouchableOpacity style={styles.copyButton} onPress={handleCopyCode}>
                <Ionicons name="copy-outline" size={20} color={colors.haven.navy[900]} />
              </TouchableOpacity>
            </View>

            <View style={styles.divider} />

            <Text style={styles.linkLabel}>Or share your link</Text>
            <TouchableOpacity style={styles.linkRow} onPress={handleCopyLink}>
              <Text style={styles.linkValue} numberOfLines={1}>
                {stats.shareUrl}
              </Text>
              <Ionicons name="copy-outline" size={16} color={colors.haven.champagne[500]} />
            </TouchableOpacity>
          </Card>
        )}

        {/* Share Button */}
        <TouchableOpacity style={styles.shareButton} onPress={handleShare}>
          <Ionicons name="share-outline" size={24} color={colors.white} />
          <Text style={styles.shareButtonText}>Share with Friends</Text>
        </TouchableOpacity>

        {/* Referral History */}
        {referrals.length > 0 && (
          <View style={styles.historySection}>
            <Text style={styles.sectionTitle}>Referral History</Text>
            {referrals.map((referral) => (
              <Card key={referral.id} style={styles.referralCard}>
                <View style={styles.referralHeader}>
                  <View style={styles.referralInfo}>
                    <Text style={styles.referralEmail}>
                      {referral.referee
                        ? `${referral.referee.firstName} ${referral.referee.lastName}`
                        : referral.refereeEmail || 'Shared Link'}
                    </Text>
                    <Text style={styles.referralDate}>
                      {new Date(referral.createdAt).toLocaleDateString()}
                    </Text>
                  </View>
                  <View
                    style={[
                      styles.statusBadge,
                      { backgroundColor: `${getStatusColor(referral.status)}20` },
                    ]}
                  >
                    <Text
                      style={[styles.statusText, { color: getStatusColor(referral.status) }]}
                    >
                      {getStatusLabel(referral.status)}
                    </Text>
                  </View>
                </View>
                {referral.rewardEarned && (
                  <View style={styles.rewardRow}>
                    <Ionicons name="checkmark-circle" size={16} color={colors.status.success} />
                    <Text style={styles.rewardText}>
                      +${referral.rewardAmount} earned
                    </Text>
                  </View>
                )}
              </Card>
            ))}
          </View>
        )}

        {/* How It Works */}
        <Card style={styles.howItWorksCard}>
          <Text style={styles.howItWorksTitle}>How It Works</Text>
          <View style={styles.step}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>1</Text>
            </View>
            <View style={styles.stepContent}>
              <Text style={styles.stepTitle}>Share Your Code</Text>
              <Text style={styles.stepDescription}>
                Send your referral code or link to friends and family
              </Text>
            </View>
          </View>
          <View style={styles.step}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>2</Text>
            </View>
            <View style={styles.stepContent}>
              <Text style={styles.stepTitle}>They Sign Up</Text>
              <Text style={styles.stepDescription}>
                When they create a Haven account using your code
              </Text>
            </View>
          </View>
          <View style={styles.step}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>3</Text>
            </View>
            <View style={styles.stepContent}>
              <Text style={styles.stepTitle}>You Both Earn</Text>
              <Text style={styles.stepDescription}>
                When they subscribe, you both get $50 credit
              </Text>
            </View>
          </View>
        </Card>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[10],
  },
  heroCard: {
    padding: spacing[6],
    alignItems: 'center',
    marginBottom: spacing[4],
    backgroundColor: colors.haven.navy[900],
  },
  heroIcon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.haven.navy[800],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  heroTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    textAlign: 'center',
    marginBottom: spacing[2],
  },
  heroSubtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.champagne[200],
    textAlign: 'center',
    lineHeight: 22,
  },
  statsRow: {
    flexDirection: 'row',
    gap: spacing[3],
    marginBottom: spacing[4],
  },
  statCard: {
    flex: 1,
    padding: spacing[4],
    alignItems: 'center',
  },
  statValue: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.navy[900],
  },
  statLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  codeCard: {
    padding: spacing[5],
    marginBottom: spacing[4],
  },
  codeLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[2],
  },
  codeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  codeValue: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.navy[900],
    letterSpacing: 2,
  },
  copyButton: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.background.secondary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  divider: {
    height: 1,
    backgroundColor: colors.border.light,
    marginVertical: spacing[4],
  },
  linkLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[2],
  },
  linkRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  linkValue: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
  },
  shareButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    backgroundColor: colors.haven.navy[900],
    paddingVertical: spacing[4],
    borderRadius: borderRadius.xl,
    marginBottom: spacing[6],
  },
  shareButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  historySection: {
    marginBottom: spacing[6],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[3],
  },
  referralCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  referralHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  referralInfo: {
    flex: 1,
  },
  referralEmail: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  referralDate: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  statusBadge: {
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
  },
  statusText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
  },
  rewardRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  rewardText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.success,
  },
  howItWorksCard: {
    padding: spacing[5],
  },
  howItWorksTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[4],
  },
  step: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: spacing[4],
  },
  stepNumber: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  stepNumberText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.champagne[600],
  },
  stepContent: {
    flex: 1,
  },
  stepTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  stepDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
  },
});
