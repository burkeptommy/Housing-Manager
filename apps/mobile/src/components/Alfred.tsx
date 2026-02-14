import React from 'react';
import { View, StyleSheet, ViewStyle, Animated } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, borderRadius } from '../lib/theme';
import { AlfredLogo } from './AlfredIcon';

// =============================================================================
// TYPES
// =============================================================================

interface AlfredAvatarProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  style?: ViewStyle;
  variant?: 'light' | 'dark'; // background context
}

// =============================================================================
// SIZE CONFIG
// =============================================================================

const SIZES = {
  sm: { container: 32, logo: 28 },
  md: { container: 44, logo: 40 },
  lg: { container: 56, logo: 52 },
  xl: { container: 72, logo: 68 },
};

// =============================================================================
// ALFRED AVATAR COMPONENT
// =============================================================================

/**
 * Alfred AI avatar with the new A-frame house logo
 * variant='light' = navy house (for light backgrounds)
 * variant='dark' = white house (for dark backgrounds)
 */
export function AlfredAvatar({ size = 'md', style, variant = 'light' }: AlfredAvatarProps) {
  const sizeConfig = SIZES[size] || SIZES.md;

  return (
    <View
      style={[
        styles.container,
        {
          width: sizeConfig.container,
          height: sizeConfig.container,
          borderRadius: sizeConfig.container / 2,
        },
        style,
      ]}
    >
      <AlfredLogo size={sizeConfig.logo} variant={variant} />
    </View>
  );
}

// =============================================================================
// ALFRED TYPING INDICATOR
// =============================================================================

interface TypingIndicatorProps {
  dot1Opacity: Animated.Value;
  dot2Opacity: Animated.Value;
  dot3Opacity: Animated.Value;
}

export function AlfredTypingIndicator({ dot1Opacity, dot2Opacity, dot3Opacity }: TypingIndicatorProps) {
  return (
    <View style={styles.typingContainer}>
      <AlfredAvatar size="sm" />
      <View style={styles.typingBubble}>
        <View style={styles.typingDots}>
          <Animated.View style={[styles.dot, { opacity: dot1Opacity }]} />
          <Animated.View style={[styles.dot, { opacity: dot2Opacity }]} />
          <Animated.View style={[styles.dot, { opacity: dot3Opacity }]} />
        </View>
      </View>
    </View>
  );
}

// =============================================================================
// ALFRED CARD COMPONENT
// =============================================================================

interface AlfredCardProps {
  message?: string;
  showActions?: boolean;
  onChat?: () => void;
}

/**
 * Alfred AI card with message and optional actions
 */
export function AlfredCard({ message, showActions, onChat }: AlfredCardProps) {
  return (
    <View style={styles.card}>
      <View style={styles.cardHeader}>
        <AlfredAvatar size="md" />
        <View style={styles.cardInfo}>
          <View style={styles.cardNameRow}>
            <Ionicons name="sparkles" size={14} color={colors.haven.purple[500]} />
          </View>
        </View>
      </View>
      {message && <View style={styles.cardMessage} />}
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.haven.purple[50],
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: 16,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  cardInfo: {
    marginLeft: 12,
    flex: 1,
  },
  cardNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  cardMessage: {
    marginTop: 12,
  },
  typingContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    marginBottom: 12,
  },
  typingBubble: {
    backgroundColor: colors.gray[100],
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: borderRadius.xl,
    borderBottomLeftRadius: 4,
    marginLeft: 8,
  },
  typingDots: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.gray[400],
  },
});
