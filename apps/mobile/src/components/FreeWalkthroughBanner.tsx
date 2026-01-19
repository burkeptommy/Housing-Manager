import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../theme/colors';
import { WalkthroughScheduleModal } from './WalkthroughScheduleModal';
import { useApi } from '../lib/api';

interface FreeWalkthroughBannerProps {
  householdId: string;
  systemCount: number;
  vendorCount: number;
  billCount: number;
  zipCode?: string;
  createdAt: string;
  onDismiss?: () => void;
  compact?: boolean;
}

export function FreeWalkthroughBanner({
  householdId,
  systemCount,
  vendorCount,
  billCount,
  zipCode,
  createdAt,
  onDismiss,
  compact = false,
}: FreeWalkthroughBannerProps) {
  const api = useApi();
  const [isEligible, setIsEligible] = useState(false);
  const [hasScheduled, setHasScheduled] = useState(false);
  const [showScheduleModal, setShowScheduleModal] = useState(false);
  const [loading, setLoading] = useState(true);

  // Check eligibility based on:
  // 1. Location (Fairfield CT or Westchester NY)
  // 2. Profile completeness (< 3 systems OR < 3 vendors OR < 5 bills)
  // 3. Account age (< 30 days for best offer)

  const isQualifyingZip = (zip: string | undefined) => {
    if (!zip) return false;
    // Fairfield County CT
    if (zip.startsWith('068')) return true;
    // Westchester County NY
    if (['105', '106', '107', '108', '109'].some((p) => zip.startsWith(p)))
      return true;
    return false;
  };

  const needsWalkthrough = systemCount < 3 || vendorCount < 3 || billCount < 5;

  useEffect(() => {
    checkEligibility();
  }, [householdId, zipCode, systemCount, vendorCount, billCount]);

  const checkEligibility = async () => {
    setLoading(true);
    try {
      // First do a quick local check
      if (!isQualifyingZip(zipCode)) {
        setIsEligible(false);
        setLoading(false);
        return;
      }

      // Then verify with the API
      const response = await api.get(`/walkthrough/eligibility/${householdId}`);
      if (response.data) {
        setIsEligible(response.data.eligible);
        setHasScheduled(response.data.hasScheduled);
      }
    } catch (error) {
      // On error, fall back to local check
      if (isQualifyingZip(zipCode) && needsWalkthrough) {
        setIsEligible(true);
      }
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return null;
  }

  if (!isEligible || hasScheduled) return null;

  if (compact) {
    return (
      <TouchableOpacity
        style={styles.compactBanner}
        onPress={() => setShowScheduleModal(true)}
      >
        <LinearGradient
          colors={[colors.haven.navy[900], colors.haven.navy[800]]}
          style={styles.compactGradient}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
        >
          <View style={styles.compactIconContainer}>
            <Ionicons
              name="home"
              size={20}
              color={colors.haven.champagne[400]}
            />
          </View>
          <View style={styles.compactContent}>
            <Text style={styles.compactTitle}>Free Home Walkthrough</Text>
            <Text style={styles.compactSubtitle}>$299 value - FREE</Text>
          </View>
          <View style={styles.compactArrow}>
            <Ionicons
              name="chevron-forward"
              size={20}
              color={colors.haven.champagne[400]}
            />
          </View>
        </LinearGradient>

        <WalkthroughScheduleModal
          visible={showScheduleModal}
          onClose={() => setShowScheduleModal(false)}
          householdId={householdId}
          onScheduled={() => {
            setHasScheduled(true);
            setShowScheduleModal(false);
          }}
        />
      </TouchableOpacity>
    );
  }

  return (
    <View style={styles.banner}>
      <LinearGradient
        colors={[colors.haven.navy[900], colors.haven.navy[800]]}
        style={styles.gradient}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
      >
        <View style={styles.mainContent}>
          <View style={styles.iconContainer}>
            <Ionicons
              name="home"
              size={32}
              color={colors.haven.champagne[400]}
            />
            <View style={styles.checkBadge}>
              <Ionicons name="checkmark" size={12} color={colors.white} />
            </View>
          </View>

          <View style={styles.content}>
            <Text style={styles.title}>Free Home Walkthrough</Text>
            <Text style={styles.subtitle}>
              We'll visit your home, document all systems, and set up your
              complete maintenance schedule.
            </Text>
            <Text style={styles.value}>$299 value - FREE for beta users</Text>
          </View>
        </View>

        <View style={styles.actions}>
          <TouchableOpacity
            style={styles.scheduleButton}
            onPress={() => setShowScheduleModal(true)}
          >
            <Ionicons name="calendar" size={18} color={colors.white} />
            <Text style={styles.scheduleButtonText}>Schedule Now</Text>
          </TouchableOpacity>
        </View>

        {onDismiss && (
          <TouchableOpacity style={styles.dismissButton} onPress={onDismiss}>
            <Ionicons name="close" size={20} color={colors.white} />
          </TouchableOpacity>
        )}
      </LinearGradient>

      <WalkthroughScheduleModal
        visible={showScheduleModal}
        onClose={() => setShowScheduleModal(false)}
        householdId={householdId}
        onScheduled={() => {
          setHasScheduled(true);
          setShowScheduleModal(false);
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    marginHorizontal: 16,
    marginVertical: 12,
    borderRadius: 16,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 5,
  },
  gradient: {
    padding: 20,
  },
  mainContent: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  iconContainer: {
    position: 'relative',
    marginRight: 16,
  },
  checkBadge: {
    position: 'absolute',
    bottom: -4,
    right: -4,
    backgroundColor: colors.haven.champagne[500],
    borderRadius: 10,
    width: 20,
    height: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: {
    flex: 1,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.white,
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: colors.haven.champagne[200],
    lineHeight: 20,
    marginBottom: 8,
  },
  value: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.haven.champagne[400],
  },
  actions: {
    flexDirection: 'row',
    marginTop: 16,
  },
  scheduleButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.champagne[500],
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 8,
    gap: 8,
  },
  scheduleButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.white,
  },
  dismissButton: {
    position: 'absolute',
    top: 12,
    right: 12,
    padding: 4,
    opacity: 0.7,
  },
  // Compact styles
  compactBanner: {
    marginHorizontal: 16,
    marginVertical: 8,
    borderRadius: 12,
    overflow: 'hidden',
  },
  compactGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
  },
  compactIconContainer: {
    marginRight: 12,
  },
  compactContent: {
    flex: 1,
  },
  compactTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.white,
  },
  compactSubtitle: {
    fontSize: 12,
    color: colors.haven.champagne[300],
  },
  compactArrow: {
    marginLeft: 8,
  },
});
