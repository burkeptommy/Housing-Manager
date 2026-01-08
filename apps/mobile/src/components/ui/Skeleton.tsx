import React, { useEffect } from 'react';
import { View, StyleSheet, ViewStyle, DimensionValue } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  interpolate,
  Easing,
} from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { colors, borderRadius as br, spacing } from '../../lib/theme';

interface SkeletonProps {
  width?: DimensionValue;
  height?: number;
  borderRadius?: number;
  style?: ViewStyle;
}

export function Skeleton({
  width = '100%',
  height = 20,
  borderRadius = br.md,
  style,
}: SkeletonProps) {
  const shimmerPosition = useSharedValue(0);

  useEffect(() => {
    shimmerPosition.value = withRepeat(
      withTiming(1, {
        duration: 1200,
        easing: Easing.inOut(Easing.ease),
      }),
      -1,
      false
    );
  }, []);

  const animatedStyle = useAnimatedStyle(() => {
    const translateX = interpolate(
      shimmerPosition.value,
      [0, 1],
      [-200, 200]
    );
    return {
      transform: [{ translateX }],
    };
  });

  return (
    <View
      style={[
        styles.skeleton,
        { width, height, borderRadius },
        style,
      ]}
    >
      <Animated.View style={[styles.shimmer, animatedStyle]}>
        <LinearGradient
          colors={['transparent', 'rgba(255,255,255,0.4)', 'transparent']}
          start={{ x: 0, y: 0.5 }}
          end={{ x: 1, y: 0.5 }}
          style={styles.gradient}
        />
      </Animated.View>
    </View>
  );
}

export function SkeletonCard({ style }: { style?: ViewStyle }) {
  return (
    <View style={[styles.card, style]}>
      <View style={styles.cardHeader}>
        <Skeleton width={48} height={48} borderRadius={24} />
        <View style={styles.cardHeaderText}>
          <Skeleton width={140} height={16} />
          <Skeleton width={90} height={12} style={{ marginTop: 8 }} />
        </View>
      </View>
      <Skeleton height={14} style={{ marginTop: 16 }} />
      <Skeleton height={14} style={{ marginTop: 8, width: '75%' }} />
    </View>
  );
}

export function SkeletonListItem({ style }: { style?: ViewStyle }) {
  return (
    <View style={[styles.listItem, style]}>
      <Skeleton width={40} height={40} borderRadius={br.lg} />
      <View style={styles.listItemContent}>
        <Skeleton width={120} height={14} />
        <Skeleton width={80} height={12} style={{ marginTop: 6 }} />
      </View>
      <Skeleton width={24} height={24} borderRadius={12} />
    </View>
  );
}

export function SkeletonList({ count = 3, showCards = false }: { count?: number; showCards?: boolean }) {
  return (
    <View style={styles.list}>
      {Array.from({ length: count }).map((_, index) =>
        showCards ? (
          <SkeletonCard key={index} style={{ marginBottom: spacing[3] }} />
        ) : (
          <SkeletonListItem key={index} style={{ marginBottom: spacing[2] }} />
        )
      )}
    </View>
  );
}

export function DashboardSkeleton() {
  return (
    <View style={styles.dashboardContainer}>
      {/* Header */}
      <View style={styles.dashboardHeader}>
        <Skeleton width={100} height={14} />
        <Skeleton width={180} height={24} style={{ marginTop: 8 }} />
      </View>

      {/* Health Card */}
      <View style={[styles.card, { marginBottom: spacing[4] }]}>
        <View style={styles.healthHeader}>
          <Skeleton width={100} height={16} />
          <Skeleton width={70} height={24} borderRadius={br.full} />
        </View>
        <Skeleton width={120} height={56} style={{ marginTop: spacing[3] }} />
        <Skeleton height={8} borderRadius={4} style={{ marginTop: spacing[3] }} />
      </View>

      {/* Quick Actions */}
      <View style={styles.quickActions}>
        {Array.from({ length: 4 }).map((_, i) => (
          <View key={i} style={styles.quickActionSkeleton}>
            <Skeleton width={48} height={48} borderRadius={br.xl} />
            <Skeleton width={50} height={12} style={{ marginTop: spacing[2] }} />
          </View>
        ))}
      </View>

      {/* Section */}
      <Skeleton width={120} height={18} style={{ marginTop: spacing[6], marginBottom: spacing[3] }} />
      <SkeletonCard />
    </View>
  );
}

export function DetailSkeleton() {
  return (
    <View style={styles.detailContainer}>
      <View style={styles.detailHeader}>
        <Skeleton width={64} height={64} borderRadius={32} />
        <Skeleton width={160} height={20} style={{ marginTop: spacing[3] }} />
        <Skeleton width={100} height={14} style={{ marginTop: spacing[2] }} />
      </View>
      <View style={styles.card}>
        <SkeletonListItem />
        <SkeletonListItem />
        <SkeletonListItem />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  skeleton: {
    backgroundColor: colors.gray[200],
    overflow: 'hidden',
  },
  shimmer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    width: '200%',
  },
  gradient: {
    flex: 1,
    width: '50%',
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: br.xl,
    padding: spacing[4],
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  cardHeaderText: {
    marginLeft: spacing[3],
    flex: 1,
  },
  list: {
    padding: spacing[4],
  },
  listItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
  },
  listItemContent: {
    flex: 1,
    marginLeft: spacing[3],
  },
  dashboardContainer: {
    padding: spacing[4],
  },
  dashboardHeader: {
    marginBottom: spacing[4],
  },
  healthHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  quickActions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[3],
  },
  quickActionSkeleton: {
    width: '47%',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: br.lg,
  },
  detailContainer: {
    padding: spacing[4],
  },
  detailHeader: {
    alignItems: 'center',
    marginBottom: spacing[4],
  },
});
